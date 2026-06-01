-- ════════════════════════════════════════════════════════════════════
-- Migration 005 — Trigger follow_counts
-- Maintient followers_count / following_count dans `profiles`
-- de manière atomique lors des INSERT/DELETE sur `follows`.
-- ════════════════════════════════════════════════════════════════════

CREATE OR REPLACE FUNCTION fn_update_follow_counts()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    -- Nouvelle relation : +1 follower pour la cible, +1 following pour l'auteur
    UPDATE profiles
       SET followers_count = followers_count + 1
     WHERE user_id = NEW.following_id;

    UPDATE profiles
       SET following_count = following_count + 1
     WHERE user_id = NEW.follower_id;

    RETURN NEW;

  ELSIF TG_OP = 'DELETE' THEN
    UPDATE profiles
       SET followers_count = GREATEST(followers_count - 1, 0)
     WHERE user_id = OLD.following_id;

    UPDATE profiles
       SET following_count = GREATEST(following_count - 1, 0)
     WHERE user_id = OLD.follower_id;

    RETURN OLD;
  END IF;

  RETURN NULL;
END;
$$;

DROP TRIGGER IF EXISTS trg_follow_counts_insert ON follows;
CREATE TRIGGER trg_follow_counts_insert
  AFTER INSERT ON follows
  FOR EACH ROW EXECUTE FUNCTION fn_update_follow_counts();

DROP TRIGGER IF EXISTS trg_follow_counts_delete ON follows;
CREATE TRIGGER trg_follow_counts_delete
  AFTER DELETE ON follows
  FOR EACH ROW EXECUTE FUNCTION fn_update_follow_counts();

-- Resynchroniser les compteurs existants (migration one-shot)
UPDATE profiles p
   SET followers_count = (
         SELECT COUNT(*) FROM follows f WHERE f.following_id = p.user_id
       ),
       following_count = (
         SELECT COUNT(*) FROM follows f WHERE f.follower_id = p.user_id
       );
