-- ════════════════════════════════════════════════════════════════════
-- GBAIRAI — Migration 003 : Functions & Triggers
-- Version : 1.0.0 | Date : 2025-05-30
-- ════════════════════════════════════════════════════════════════════

-- ── AUTO-CRÉATION USER LORS DE L'INSCRIPTION ──────────────────────
CREATE OR REPLACE FUNCTION handle_new_auth_user()
RETURNS TRIGGER
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  new_user_id UUID;
BEGIN
  INSERT INTO public.users (auth_id, email, phone)
  VALUES (
    NEW.id,
    NEW.email,
    NEW.phone
  )
  RETURNING id INTO new_user_id;

  -- Audit log
  INSERT INTO public.audit_logs (user_id, action, metadata)
  VALUES (new_user_id, 'user_created', jsonb_build_object('provider', NEW.app_metadata->>'provider'));

  RETURN NEW;
END;
$$;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_auth_user();

-- ── UPDATED_AT AUTOMATIQUE ────────────────────────────────────────
CREATE OR REPLACE FUNCTION touch_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;

CREATE TRIGGER users_updated_at
  BEFORE UPDATE ON users
  FOR EACH ROW EXECUTE FUNCTION touch_updated_at();

CREATE TRIGGER profiles_updated_at
  BEFORE UPDATE ON profiles
  FOR EACH ROW EXECUTE FUNCTION touch_updated_at();

-- ── SCORE DE CONTENU ──────────────────────────────────────────────
-- Algorithme : score = (réactions * 2 + commentaires * 3 + partages * 1.5 + vues * 0.1)
--              * decay_factor(age_heures)
--              * boost_factor(niveau_gbairai)
CREATE OR REPLACE FUNCTION compute_content_score(p_content_id UUID)
RETURNS FLOAT
LANGUAGE plpgsql SECURITY DEFINER
AS $$
DECLARE
  v_reactions    BIGINT;
  v_comments     BIGINT;
  v_shares       BIGINT;
  v_views        BIGINT;
  v_age_hours    FLOAT;
  v_gbairai_lvl  TEXT;
  v_score        FLOAT;
  v_decay        FLOAT;
  v_boost        FLOAT;
BEGIN
  SELECT
    reactions_count, comments_count, shares_count, views_count,
    EXTRACT(EPOCH FROM (now() - created_at)) / 3600.0,
    gbairai_level
  INTO v_reactions, v_comments, v_shares, v_views, v_age_hours, v_gbairai_lvl
  FROM contents
  WHERE id = p_content_id;

  IF NOT FOUND THEN
    RETURN 0;
  END IF;

  -- Formule de score brut
  v_score := (v_reactions * 2.0)
           + (v_comments  * 3.0)
           + (v_shares    * 1.5)
           + (v_views     * 0.1);

  -- Decay temporel (half-life 6h)
  v_decay := POWER(0.5, v_age_hours / 6.0);

  -- Boost selon niveau gbairai
  v_boost := CASE v_gbairai_lvl
    WHEN 'legendaire'  THEN 3.0
    WHEN 'national'    THEN 2.0
    WHEN 'local'       THEN 1.5
    WHEN 'pre_gbairai' THEN 1.2
    ELSE 1.0
  END;

  RETURN GREATEST(v_score * v_decay * v_boost, 0);
END;
$$;

-- ── MISE À JOUR DU SCORE LORS D'UNE RÉACTION ─────────────────────
CREATE OR REPLACE FUNCTION on_reaction_change()
RETURNS TRIGGER
LANGUAGE plpgsql SECURITY DEFINER
AS $$
DECLARE
  v_content_id UUID;
  v_new_score  FLOAT;
BEGIN
  v_content_id := COALESCE(NEW.content_id, OLD.content_id);

  -- Recalcul compteur réactions
  UPDATE contents
  SET reactions_count = (
    SELECT COUNT(*) FROM reactions WHERE content_id = v_content_id
  )
  WHERE id = v_content_id;

  -- Recalcul score
  v_new_score := compute_content_score(v_content_id);
  UPDATE contents
  SET score = v_new_score,
      score_adjusted = v_new_score
  WHERE id = v_content_id;

  RETURN COALESCE(NEW, OLD);
END;
$$;

CREATE TRIGGER on_reaction_score_update
  AFTER INSERT OR DELETE ON reactions
  FOR EACH ROW EXECUTE FUNCTION on_reaction_change();

-- ── MISE À JOUR DU SCORE LORS D'UN COMMENTAIRE ───────────────────
CREATE OR REPLACE FUNCTION on_comment_change()
RETURNS TRIGGER
LANGUAGE plpgsql SECURITY DEFINER
AS $$
DECLARE
  v_content_id UUID;
  v_new_score  FLOAT;
BEGIN
  v_content_id := COALESCE(NEW.content_id, OLD.content_id);

  UPDATE contents
  SET comments_count = (
    SELECT COUNT(*) FROM comments
    WHERE content_id = v_content_id AND deleted_at IS NULL
  )
  WHERE id = v_content_id;

  v_new_score := compute_content_score(v_content_id);
  UPDATE contents
  SET score = v_new_score,
      score_adjusted = v_new_score
  WHERE id = v_content_id;

  RETURN COALESCE(NEW, OLD);
END;
$$;

CREATE TRIGGER on_comment_score_update
  AFTER INSERT OR DELETE ON comments
  FOR EACH ROW EXECUTE FUNCTION on_comment_change();

-- ── INCRÉMENT DE VUE (RPC sécurisé) ──────────────────────────────
CREATE OR REPLACE FUNCTION increment_view(
  p_content_id       UUID,
  p_session_id       TEXT,
  p_watch_seconds    FLOAT DEFAULT NULL,
  p_completed        BOOLEAN DEFAULT false,
  p_source           TEXT DEFAULT 'feed'
)
RETURNS void
LANGUAGE plpgsql SECURITY DEFINER
AS $$
DECLARE
  v_user_id UUID := get_my_user_id();
BEGIN
  -- Validation de la source (whitelist)
  IF p_source NOT IN ('feed','alert','profile','trending','whatsapp','external') THEN
    RAISE EXCEPTION 'invalid_source';
  END IF;

  -- Anti-double-vue (même session dans les 5 dernières minutes)
  IF EXISTS (
    SELECT 1 FROM content_views
    WHERE content_id = p_content_id
      AND session_id = p_session_id
      AND created_at > now() - interval '5 minutes'
  ) THEN
    RETURN;
  END IF;

  -- Insertion de la vue
  INSERT INTO content_views (content_id, user_id, session_id, watch_duration_seconds, completed, source)
  VALUES (p_content_id, v_user_id, p_session_id, p_watch_seconds, p_completed, p_source);

  -- Incrément atomique du compteur
  UPDATE contents
  SET views_count = views_count + 1
  WHERE id = p_content_id AND deleted_at IS NULL;
END;
$$;

-- ── DÉTECTION NIVEAU GBAIRAI ──────────────────────────────────────
-- Appelée par le score-worker Edge Function toutes les 60 secondes
CREATE OR REPLACE FUNCTION evaluate_gbairai_level(p_content_id UUID)
RETURNS TEXT
LANGUAGE plpgsql SECURITY DEFINER
AS $$
DECLARE
  v_views_1h  BIGINT;
  v_views_6h  BIGINT;
  v_reactions BIGINT;
  v_old_level TEXT;
  v_new_level TEXT;
BEGIN
  SELECT gbairai_level, reactions_count
  INTO v_old_level, v_reactions
  FROM contents
  WHERE id = p_content_id;

  -- Vues dernière heure
  SELECT COUNT(*) INTO v_views_1h
  FROM content_views
  WHERE content_id = p_content_id
    AND created_at > now() - interval '1 hour';

  -- Vues 6 dernières heures
  SELECT COUNT(*) INTO v_views_6h
  FROM content_views
  WHERE content_id = p_content_id
    AND created_at > now() - interval '6 hours';

  -- Règles de niveau (seuils définis dans le CDC)
  v_new_level := CASE
    WHEN v_views_1h >= 50000 OR v_reactions >= 10000 THEN 'legendaire'
    WHEN v_views_1h >= 10000 OR (v_views_6h >= 30000 AND v_reactions >= 2000) THEN 'national'
    WHEN v_views_1h >= 2000  OR (v_views_6h >= 5000  AND v_reactions >= 300)  THEN 'local'
    WHEN v_views_1h >= 300   OR v_reactions >= 50                              THEN 'pre_gbairai'
    ELSE NULL
  END;

  -- Mise à jour uniquement si changement de niveau (évite les triggers inutiles)
  IF v_new_level IS DISTINCT FROM v_old_level THEN
    UPDATE contents
    SET gbairai_level = v_new_level
    WHERE id = p_content_id;
  END IF;

  RETURN v_new_level;
END;
$$;

-- ── COMPTEURS PROFIL (followers / following / posts) ───────────────
CREATE OR REPLACE FUNCTION on_follow_change()
RETURNS TRIGGER
LANGUAGE plpgsql SECURITY DEFINER
AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE profiles SET followers_count = followers_count + 1 WHERE user_id = NEW.following_id;
    UPDATE profiles SET following_count = following_count + 1 WHERE user_id = NEW.follower_id;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE profiles SET followers_count = GREATEST(followers_count - 1, 0) WHERE user_id = OLD.following_id;
    UPDATE profiles SET following_count = GREATEST(following_count - 1, 0) WHERE user_id = OLD.follower_id;
  END IF;
  RETURN COALESCE(NEW, OLD);
END;
$$;

CREATE TRIGGER on_follow_count_update
  AFTER INSERT OR DELETE ON follows
  FOR EACH ROW EXECUTE FUNCTION on_follow_change();

CREATE OR REPLACE FUNCTION on_content_change()
RETURNS TRIGGER
LANGUAGE plpgsql SECURITY DEFINER
AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE profiles SET posts_count = posts_count + 1 WHERE user_id = NEW.user_id;
  ELSIF TG_OP = 'UPDATE' AND NEW.deleted_at IS NOT NULL AND OLD.deleted_at IS NULL THEN
    UPDATE profiles SET posts_count = GREATEST(posts_count - 1, 0) WHERE user_id = NEW.user_id;
  END IF;
  RETURN NEW;
END;
$$;

CREATE TRIGGER on_content_count_update
  AFTER INSERT OR UPDATE ON contents
  FOR EACH ROW EXECUTE FUNCTION on_content_change();

-- ── NIVEAU UTILISATEUR (gamification) ────────────────────────────
CREATE OR REPLACE FUNCTION update_user_level()
RETURNS TRIGGER
LANGUAGE plpgsql SECURITY DEFINER
AS $$
DECLARE
  v_new_level TEXT;
BEGIN
  v_new_level := CASE
    WHEN NEW.level_score >= 100000 THEN 'legende'
    WHEN NEW.level_score >= 10000  THEN 'grand_patron'
    WHEN NEW.level_score >= 1000   THEN 'influenceur'
    ELSE 'debutant'
  END;

  IF v_new_level != NEW.level THEN
    NEW.level := v_new_level;
  END IF;

  RETURN NEW;
END;
$$;

CREATE TRIGGER on_level_score_change
  BEFORE UPDATE OF level_score ON profiles
  FOR EACH ROW EXECUTE FUNCTION update_user_level();

-- ── LIMITE POSTS ANONYMES ─────────────────────────────────────────
CREATE OR REPLACE FUNCTION check_anonymous_quota()
RETURNS TRIGGER
LANGUAGE plpgsql SECURITY DEFINER
AS $$
DECLARE
  v_anon_count INT;
  v_reset_at   TIMESTAMPTZ;
BEGIN
  IF NOT NEW.is_anonymous THEN
    RETURN NEW;
  END IF;

  SELECT anonymous_posts_count, anonymous_reset_at
  INTO v_anon_count, v_reset_at
  FROM users WHERE id = NEW.user_id;

  -- Reset si la fenêtre de 24h est dépassée
  IF v_reset_at < now() - interval '24 hours' THEN
    UPDATE users
    SET anonymous_posts_count = 0, anonymous_reset_at = now()
    WHERE id = NEW.user_id;
    v_anon_count := 0;
  END IF;

  -- Limite : 3 posts anonymes par 24h (valeur du CDC)
  IF v_anon_count >= 3 THEN
    RAISE EXCEPTION 'anonymous_quota_exceeded';
  END IF;

  UPDATE users
  SET anonymous_posts_count = anonymous_posts_count + 1
  WHERE id = NEW.user_id;

  RETURN NEW;
END;
$$;

CREATE TRIGGER on_anonymous_content_insert
  BEFORE INSERT ON contents
  FOR EACH ROW EXECUTE FUNCTION check_anonymous_quota();

-- ── GDPR : ANONYMISATION COMPTE ───────────────────────────────────
CREATE OR REPLACE FUNCTION gdpr_anonymize_user(p_user_id UUID)
RETURNS void
LANGUAGE plpgsql SECURITY DEFINER
AS $$
DECLARE
  v_anon_suffix TEXT := substring(gen_random_uuid()::text, 1, 8);
BEGIN
  -- Vérifie que l'appelant est le propriétaire ou admin
  IF get_my_user_id() != p_user_id AND NOT is_moderator() THEN
    RAISE EXCEPTION 'forbidden';
  END IF;

  -- Anonymisation des données personnelles
  UPDATE users
  SET
    phone    = NULL,
    email    = 'deleted_' || v_anon_suffix || '@gbairai.deleted',
    username = 'deleted_' || v_anon_suffix,
    is_banned = true
  WHERE id = p_user_id;

  UPDATE profiles
  SET
    display_name = 'Utilisateur supprimé',
    bio          = NULL,
    avatar_url   = NULL,
    banner_url   = NULL,
    fcm_token    = NULL
  WHERE user_id = p_user_id;

  -- Suppression des données sensibles
  DELETE FROM device_fingerprints WHERE user_id = p_user_id;
  DELETE FROM notifications WHERE user_id = p_user_id;
  DELETE FROM blocks WHERE blocker_id = p_user_id OR blocked_id = p_user_id;

  -- Anonymisation du contenu (conservation avec auteur masqué)
  UPDATE contents
  SET is_anonymous = true, anon_username = 'deleted_' || v_anon_suffix
  WHERE user_id = p_user_id AND deleted_at IS NULL;

  INSERT INTO audit_logs (user_id, action, metadata)
  VALUES (p_user_id, 'gdpr_anonymized', jsonb_build_object('timestamp', now()));
END;
$$;

-- ── ANTI-SPAM : RATE LIMIT CÔTÉ DB ───────────────────────────────
-- Complément au rate limiting côté client
CREATE OR REPLACE FUNCTION check_report_spam(p_reporter_id UUID)
RETURNS void
LANGUAGE plpgsql SECURITY DEFINER
AS $$
DECLARE
  v_count INT;
BEGIN
  SELECT COUNT(*) INTO v_count
  FROM reports
  WHERE reporter_id = p_reporter_id
    AND created_at > now() - interval '1 hour';

  IF v_count >= 10 THEN
    RAISE EXCEPTION 'rate_limit_exceeded';
  END IF;
END;
$$;

CREATE OR REPLACE FUNCTION before_report_insert()
RETURNS TRIGGER
LANGUAGE plpgsql SECURITY DEFINER
AS $$
BEGIN
  PERFORM check_report_spam(NEW.reporter_id);
  RETURN NEW;
END;
$$;

CREATE TRIGGER on_report_insert_spam_check
  BEFORE INSERT ON reports
  FOR EACH ROW EXECUTE FUNCTION before_report_insert();

-- ── INDEX SUPPLÉMENTAIRES POUR LES FONCTIONS ─────────────────────
CREATE INDEX IF NOT EXISTS idx_users_auth_id ON users(auth_id);
CREATE INDEX IF NOT EXISTS idx_blocks_pair ON blocks(blocker_id, blocked_id);
CREATE INDEX IF NOT EXISTS idx_follows_pair ON follows(follower_id, following_id);
CREATE INDEX IF NOT EXISTS idx_views_session ON content_views(content_id, session_id, created_at DESC);
