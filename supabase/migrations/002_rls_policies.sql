-- ════════════════════════════════════════════════════════════════════
-- GBAIRAI — Migration 002 : Row Level Security
-- Version : 1.0.0 | Date : 2025-05-30
-- ════════════════════════════════════════════════════════════════════

-- ── ACTIVER RLS ────────────────────────────────────────────────────
ALTER TABLE users               ENABLE ROW LEVEL SECURITY;
ALTER TABLE profiles            ENABLE ROW LEVEL SECURITY;
ALTER TABLE device_fingerprints ENABLE ROW LEVEL SECURITY;
ALTER TABLE audit_logs          ENABLE ROW LEVEL SECURITY;
ALTER TABLE contents            ENABLE ROW LEVEL SECURITY;
ALTER TABLE reactions           ENABLE ROW LEVEL SECURITY;
ALTER TABLE voice_reactions     ENABLE ROW LEVEL SECURITY;
ALTER TABLE comments            ENABLE ROW LEVEL SECURITY;
ALTER TABLE content_views       ENABLE ROW LEVEL SECURITY;
ALTER TABLE gbairai_alerts      ENABLE ROW LEVEL SECURITY;
ALTER TABLE follows             ENABLE ROW LEVEL SECURITY;
ALTER TABLE hashtags            ENABLE ROW LEVEL SECURITY;
ALTER TABLE content_hashtags    ENABLE ROW LEVEL SECURITY;
ALTER TABLE reports             ENABLE ROW LEVEL SECURITY;
ALTER TABLE blocks              ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications       ENABLE ROW LEVEL SECURITY;

-- ── HELPER FUNCTIONS ──────────────────────────────────────────────
-- Récupère le user_id interne depuis l'auth.uid()
CREATE OR REPLACE FUNCTION get_my_user_id()
RETURNS UUID
LANGUAGE sql STABLE SECURITY DEFINER
AS $$
  SELECT id FROM users WHERE auth_id = auth.uid() LIMIT 1;
$$;

-- Vérifie si l'utilisateur courant est banni
CREATE OR REPLACE FUNCTION is_banned()
RETURNS BOOLEAN
LANGUAGE sql STABLE SECURITY DEFINER
AS $$
  SELECT COALESCE(
    (SELECT is_banned OR (ban_until IS NOT NULL AND ban_until > now())
     FROM users WHERE auth_id = auth.uid() LIMIT 1),
    false
  );
$$;

-- Vérifie si l'utilisateur courant est admin/moderator
CREATE OR REPLACE FUNCTION is_moderator()
RETURNS BOOLEAN
LANGUAGE sql STABLE SECURITY DEFINER
AS $$
  SELECT COALESCE(
    (SELECT role IN ('moderator','admin') FROM users WHERE auth_id = auth.uid() LIMIT 1),
    false
  );
$$;

-- Vérifie si target_id bloque le viewer ou est bloqué par le viewer
CREATE OR REPLACE FUNCTION is_blocked_by(target_user_id UUID)
RETURNS BOOLEAN
LANGUAGE sql STABLE SECURITY DEFINER
AS $$
  SELECT EXISTS (
    SELECT 1 FROM blocks
    WHERE (blocker_id = get_my_user_id() AND blocked_id = target_user_id)
       OR (blocker_id = target_user_id AND blocked_id = get_my_user_id())
  );
$$;

-- Vérifie si le viewer suit target_user_id
CREATE OR REPLACE FUNCTION i_follow(target_user_id UUID)
RETURNS BOOLEAN
LANGUAGE sql STABLE SECURITY DEFINER
AS $$
  SELECT EXISTS (
    SELECT 1 FROM follows
    WHERE follower_id = get_my_user_id() AND following_id = target_user_id
  );
$$;

-- ── USERS ─────────────────────────────────────────────────────────
-- Lecture : chacun peut voir les utilisateurs non bannis (profils publics)
CREATE POLICY "users_select" ON users
  FOR SELECT USING (
    NOT is_banned()
    OR id = get_my_user_id()
    OR is_moderator()
  );

-- Insertion : uniquement via le trigger create_user_on_signup (service role)
CREATE POLICY "users_insert" ON users
  FOR INSERT WITH CHECK (auth_id = auth.uid());

-- Mise à jour : uniquement ses propres données (hors role/is_banned)
CREATE POLICY "users_update_own" ON users
  FOR UPDATE USING (auth_id = auth.uid())
  WITH CHECK (
    auth_id = auth.uid()
    AND role = (SELECT role FROM users WHERE auth_id = auth.uid())
    AND is_banned = (SELECT is_banned FROM users WHERE auth_id = auth.uid())
  );

-- Modérateurs peuvent bannir
CREATE POLICY "users_update_moderator" ON users
  FOR UPDATE USING (is_moderator());

-- Suppression : uniquement admins
CREATE POLICY "users_delete_admin" ON users
  FOR DELETE USING (
    (SELECT role FROM users WHERE auth_id = auth.uid()) = 'admin'
  );

-- ── PROFILES ──────────────────────────────────────────────────────
CREATE POLICY "profiles_select" ON profiles
  FOR SELECT USING (
    NOT is_blocked_by(user_id)
    OR user_id = get_my_user_id()
    OR is_moderator()
  );

CREATE POLICY "profiles_insert" ON profiles
  FOR INSERT WITH CHECK (user_id = get_my_user_id());

CREATE POLICY "profiles_update_own" ON profiles
  FOR UPDATE USING (user_id = get_my_user_id());

CREATE POLICY "profiles_update_moderator" ON profiles
  FOR UPDATE USING (is_moderator());

-- ── DEVICE_FINGERPRINTS ───────────────────────────────────────────
-- Lecture : uniquement admins (données sensibles)
CREATE POLICY "fingerprints_select_admin" ON device_fingerprints
  FOR SELECT USING (is_moderator());

-- Insertion : utilisateur authentifié pour son propre compte
CREATE POLICY "fingerprints_insert" ON device_fingerprints
  FOR INSERT WITH CHECK (user_id = get_my_user_id());

-- ── AUDIT_LOGS ────────────────────────────────────────────────────
CREATE POLICY "audit_logs_select_admin" ON audit_logs
  FOR SELECT USING (is_moderator());

CREATE POLICY "audit_logs_insert" ON audit_logs
  FOR INSERT WITH CHECK (true); -- Service role inserts via functions

-- ── CONTENTS ──────────────────────────────────────────────────────
-- Lecture publique : contenus approuvés + public + non supprimés + non bloqués
CREATE POLICY "contents_select_public" ON contents
  FOR SELECT USING (
    deleted_at IS NULL
    AND moderation_status = 'approved'
    AND (
      visibility = 'public'
      OR user_id = get_my_user_id()
      OR (visibility = 'followers' AND i_follow(user_id))
    )
    AND NOT is_blocked_by(user_id)
  );

-- Modérateurs voient tout
CREATE POLICY "contents_select_moderator" ON contents
  FOR SELECT USING (is_moderator());

-- Insertion : utilisateur authentifié non banni
CREATE POLICY "contents_insert" ON contents
  FOR INSERT WITH CHECK (
    user_id = get_my_user_id()
    AND NOT is_banned()
  );

-- Mise à jour : uniquement son propre contenu (hors champs de modération)
CREATE POLICY "contents_update_own" ON contents
  FOR UPDATE USING (
    user_id = get_my_user_id()
    AND deleted_at IS NULL
  )
  WITH CHECK (
    user_id = get_my_user_id()
    AND moderation_status = (SELECT moderation_status FROM contents WHERE id = contents.id)
    AND moderation_score = (SELECT moderation_score FROM contents WHERE id = contents.id)
  );

-- Modérateurs peuvent modifier le statut de modération
CREATE POLICY "contents_update_moderator" ON contents
  FOR UPDATE USING (is_moderator());

-- Suppression logique : uniquement son propre contenu
CREATE POLICY "contents_delete_own" ON contents
  FOR UPDATE USING (
    user_id = get_my_user_id()
  )
  WITH CHECK (deleted_at IS NOT NULL);

-- ── REACTIONS ─────────────────────────────────────────────────────
CREATE POLICY "reactions_select" ON reactions
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM contents c
      WHERE c.id = reactions.content_id
        AND c.deleted_at IS NULL
        AND NOT is_blocked_by(c.user_id)
    )
  );

CREATE POLICY "reactions_insert" ON reactions
  FOR INSERT WITH CHECK (
    user_id = get_my_user_id()
    AND NOT is_banned()
    AND EXISTS (
      SELECT 1 FROM contents c
      WHERE c.id = content_id
        AND c.deleted_at IS NULL
        AND c.moderation_status = 'approved'
    )
  );

-- Une seule réaction par utilisateur par contenu (enforced par UNIQUE aussi)
CREATE POLICY "reactions_update_own" ON reactions
  FOR UPDATE USING (user_id = get_my_user_id());

CREATE POLICY "reactions_delete_own" ON reactions
  FOR DELETE USING (user_id = get_my_user_id());

-- ── VOICE_REACTIONS ───────────────────────────────────────────────
CREATE POLICY "voice_reactions_select" ON voice_reactions
  FOR SELECT USING (
    deleted_at IS NULL
    AND EXISTS (
      SELECT 1 FROM contents c
      WHERE c.id = voice_reactions.content_id
        AND c.deleted_at IS NULL
        AND NOT is_blocked_by(c.user_id)
    )
    AND NOT is_blocked_by(user_id)
  );

CREATE POLICY "voice_reactions_insert" ON voice_reactions
  FOR INSERT WITH CHECK (
    user_id = get_my_user_id()
    AND NOT is_banned()
  );

CREATE POLICY "voice_reactions_delete_own" ON voice_reactions
  FOR DELETE USING (user_id = get_my_user_id());

-- ── COMMENTS ──────────────────────────────────────────────────────
CREATE POLICY "comments_select" ON comments
  FOR SELECT USING (
    deleted_at IS NULL
    AND NOT is_blocked_by(user_id)
    AND EXISTS (
      SELECT 1 FROM contents c
      WHERE c.id = comments.content_id
        AND c.deleted_at IS NULL
    )
  );

CREATE POLICY "comments_insert" ON comments
  FOR INSERT WITH CHECK (
    user_id = get_my_user_id()
    AND NOT is_banned()
    AND EXISTS (
      SELECT 1 FROM contents c
      WHERE c.id = content_id
        AND c.deleted_at IS NULL
        AND c.moderation_status = 'approved'
    )
  );

CREATE POLICY "comments_update_own" ON comments
  FOR UPDATE USING (user_id = get_my_user_id() AND deleted_at IS NULL);

CREATE POLICY "comments_delete_own" ON comments
  FOR DELETE USING (user_id = get_my_user_id());

CREATE POLICY "comments_update_moderator" ON comments
  FOR UPDATE USING (is_moderator());

-- ── CONTENT_VIEWS ─────────────────────────────────────────────────
-- Insertion libre (vues anonymes possibles), lecture moderateurs seulement
CREATE POLICY "views_insert" ON content_views
  FOR INSERT WITH CHECK (true);

CREATE POLICY "views_select_moderator" ON content_views
  FOR SELECT USING (
    user_id = get_my_user_id()
    OR is_moderator()
  );

-- ── GBAIRAI_ALERTS ────────────────────────────────────────────────
-- Alertes publiques, tout le monde peut voir
CREATE POLICY "alerts_select" ON gbairai_alerts
  FOR SELECT USING (true);

-- Création uniquement via Edge Functions (service role)
CREATE POLICY "alerts_insert_service" ON gbairai_alerts
  FOR INSERT WITH CHECK (is_moderator());

-- ── FOLLOWS ───────────────────────────────────────────────────────
CREATE POLICY "follows_select" ON follows
  FOR SELECT USING (
    follower_id = get_my_user_id()
    OR following_id = get_my_user_id()
    OR NOT is_blocked_by(follower_id)
  );

CREATE POLICY "follows_insert" ON follows
  FOR INSERT WITH CHECK (
    follower_id = get_my_user_id()
    AND NOT is_banned()
    AND NOT is_blocked_by(following_id)
    AND following_id != get_my_user_id()
  );

CREATE POLICY "follows_delete_own" ON follows
  FOR DELETE USING (follower_id = get_my_user_id());

-- ── HASHTAGS ──────────────────────────────────────────────────────
CREATE POLICY "hashtags_select" ON hashtags
  FOR SELECT USING (true);

-- Service role uniquement pour les mises à jour de compteurs
CREATE POLICY "hashtags_insert_service" ON hashtags
  FOR INSERT WITH CHECK (is_moderator());

-- ── CONTENT_HASHTAGS ──────────────────────────────────────────────
CREATE POLICY "content_hashtags_select" ON content_hashtags
  FOR SELECT USING (true);

CREATE POLICY "content_hashtags_insert" ON content_hashtags
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM contents c
      WHERE c.id = content_id AND c.user_id = get_my_user_id()
    )
  );

-- ── REPORTS ───────────────────────────────────────────────────────
CREATE POLICY "reports_select_own" ON reports
  FOR SELECT USING (
    reporter_id = get_my_user_id()
    OR is_moderator()
  );

CREATE POLICY "reports_insert" ON reports
  FOR INSERT WITH CHECK (
    reporter_id = get_my_user_id()
    AND NOT is_banned()
  );

CREATE POLICY "reports_update_moderator" ON reports
  FOR UPDATE USING (is_moderator());

-- ── BLOCKS ────────────────────────────────────────────────────────
CREATE POLICY "blocks_select_own" ON blocks
  FOR SELECT USING (
    blocker_id = get_my_user_id()
    OR blocked_id = get_my_user_id()
  );

CREATE POLICY "blocks_insert" ON blocks
  FOR INSERT WITH CHECK (
    blocker_id = get_my_user_id()
    AND blocker_id != blocked_id
  );

CREATE POLICY "blocks_delete_own" ON blocks
  FOR DELETE USING (blocker_id = get_my_user_id());

-- ── NOTIFICATIONS ─────────────────────────────────────────────────
CREATE POLICY "notifs_select_own" ON notifications
  FOR SELECT USING (user_id = get_my_user_id());

-- Création via Edge Functions (service role)
CREATE POLICY "notifs_insert_service" ON notifications
  FOR INSERT WITH CHECK (
    user_id = get_my_user_id()
    OR is_moderator()
  );

CREATE POLICY "notifs_update_own" ON notifications
  FOR UPDATE USING (user_id = get_my_user_id());

CREATE POLICY "notifs_delete_own" ON notifications
  FOR DELETE USING (user_id = get_my_user_id());
