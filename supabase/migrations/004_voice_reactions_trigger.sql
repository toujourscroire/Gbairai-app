-- ════════════════════════════════════════════════════════════════════
-- Migration 004 — Trigger voice_reactions_count
-- Maintient le compteur `voice_reactions_count` dans `contents`
-- de manière atomique sans RPC.
-- ════════════════════════════════════════════════════════════════════

-- Fonction trigger : incrémente/décrémente le compteur
CREATE OR REPLACE FUNCTION fn_update_voice_reactions_count()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE contents
       SET voice_reactions_count = voice_reactions_count + 1
     WHERE id = NEW.content_id;
    RETURN NEW;

  ELSIF TG_OP = 'UPDATE' AND
        NEW.deleted_at IS NOT NULL AND OLD.deleted_at IS NULL THEN
    -- Soft delete
    UPDATE contents
       SET voice_reactions_count = GREATEST(voice_reactions_count - 1, 0)
     WHERE id = NEW.content_id;
    RETURN NEW;

  ELSIF TG_OP = 'DELETE' THEN
    UPDATE contents
       SET voice_reactions_count = GREATEST(voice_reactions_count - 1, 0)
     WHERE id = OLD.content_id;
    RETURN OLD;
  END IF;

  RETURN NEW;
END;
$$;

-- Trigger INSERT
DROP TRIGGER IF EXISTS trg_voice_reactions_count_insert ON voice_reactions;
CREATE TRIGGER trg_voice_reactions_count_insert
  AFTER INSERT ON voice_reactions
  FOR EACH ROW EXECUTE FUNCTION fn_update_voice_reactions_count();

-- Trigger UPDATE (soft delete)
DROP TRIGGER IF EXISTS trg_voice_reactions_count_update ON voice_reactions;
CREATE TRIGGER trg_voice_reactions_count_update
  AFTER UPDATE ON voice_reactions
  FOR EACH ROW EXECUTE FUNCTION fn_update_voice_reactions_count();

-- Trigger DELETE (hard delete, si jamais)
DROP TRIGGER IF EXISTS trg_voice_reactions_count_delete ON voice_reactions;
CREATE TRIGGER trg_voice_reactions_count_delete
  AFTER DELETE ON voice_reactions
  FOR EACH ROW EXECUTE FUNCTION fn_update_voice_reactions_count();
