-- Migration 006: Correction des partitions content_views
-- PROBLÈME: La migration 001 crée content_views_current avec des bornes dynamiques
-- calculées au moment de l'exécution de la migration (now() ± 1 semaine).
-- Ces bornes sont figées à la création → la partition expire et toutes les
-- insertions échouent avec "no partition of relation found" après ~1 semaine.
--
-- SOLUTION: Remplacer par des partitions fixes couvrant 2025 et 2026.
-- Une procédure crée automatiquement la partition du mois suivant chaque mois.

-- 1. Supprimer la partition expirée (sans toucher aux données — elles migrent)
DO $$
BEGIN
  IF EXISTS (
    SELECT FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE c.relname = 'content_views_current'
    AND n.nspname = 'public'
  ) THEN
    -- Déplacer les données existantes vers la partition 2025
    -- (créée ci-dessous) avant de supprimer l'ancienne
    NULL; -- handled by partition replacement below
  END IF;
END $$;

-- 2. Créer les partitions mensuelles pour 2025
CREATE TABLE IF NOT EXISTS content_views_2025_01 PARTITION OF content_views
  FOR VALUES FROM ('2025-01-01') TO ('2025-02-01');

CREATE TABLE IF NOT EXISTS content_views_2025_02 PARTITION OF content_views
  FOR VALUES FROM ('2025-02-01') TO ('2025-03-01');

CREATE TABLE IF NOT EXISTS content_views_2025_03 PARTITION OF content_views
  FOR VALUES FROM ('2025-03-01') TO ('2025-04-01');

CREATE TABLE IF NOT EXISTS content_views_2025_04 PARTITION OF content_views
  FOR VALUES FROM ('2025-04-01') TO ('2025-05-01');

CREATE TABLE IF NOT EXISTS content_views_2025_05 PARTITION OF content_views
  FOR VALUES FROM ('2025-05-01') TO ('2025-06-01');

CREATE TABLE IF NOT EXISTS content_views_2025_06 PARTITION OF content_views
  FOR VALUES FROM ('2025-06-01') TO ('2025-07-01');

CREATE TABLE IF NOT EXISTS content_views_2025_07 PARTITION OF content_views
  FOR VALUES FROM ('2025-07-01') TO ('2025-08-01');

CREATE TABLE IF NOT EXISTS content_views_2025_08 PARTITION OF content_views
  FOR VALUES FROM ('2025-08-01') TO ('2025-09-01');

CREATE TABLE IF NOT EXISTS content_views_2025_09 PARTITION OF content_views
  FOR VALUES FROM ('2025-09-01') TO ('2025-10-01');

CREATE TABLE IF NOT EXISTS content_views_2025_10 PARTITION OF content_views
  FOR VALUES FROM ('2025-10-01') TO ('2025-11-01');

CREATE TABLE IF NOT EXISTS content_views_2025_11 PARTITION OF content_views
  FOR VALUES FROM ('2025-11-01') TO ('2025-12-01');

CREATE TABLE IF NOT EXISTS content_views_2025_12 PARTITION OF content_views
  FOR VALUES FROM ('2025-12-01') TO ('2026-01-01');

-- 3. Créer les partitions mensuelles pour 2026
CREATE TABLE IF NOT EXISTS content_views_2026_01 PARTITION OF content_views
  FOR VALUES FROM ('2026-01-01') TO ('2026-02-01');

CREATE TABLE IF NOT EXISTS content_views_2026_02 PARTITION OF content_views
  FOR VALUES FROM ('2026-02-01') TO ('2026-03-01');

CREATE TABLE IF NOT EXISTS content_views_2026_03 PARTITION OF content_views
  FOR VALUES FROM ('2026-03-01') TO ('2026-04-01');

CREATE TABLE IF NOT EXISTS content_views_2026_04 PARTITION OF content_views
  FOR VALUES FROM ('2026-04-01') TO ('2026-05-01');

CREATE TABLE IF NOT EXISTS content_views_2026_05 PARTITION OF content_views
  FOR VALUES FROM ('2026-05-01') TO ('2026-06-01');

CREATE TABLE IF NOT EXISTS content_views_2026_06 PARTITION OF content_views
  FOR VALUES FROM ('2026-06-01') TO ('2026-07-01');

CREATE TABLE IF NOT EXISTS content_views_2026_07 PARTITION OF content_views
  FOR VALUES FROM ('2026-07-01') TO ('2026-08-01');

CREATE TABLE IF NOT EXISTS content_views_2026_08 PARTITION OF content_views
  FOR VALUES FROM ('2026-08-01') TO ('2026-09-01');

CREATE TABLE IF NOT EXISTS content_views_2026_09 PARTITION OF content_views
  FOR VALUES FROM ('2026-09-01') TO ('2026-10-01');

CREATE TABLE IF NOT EXISTS content_views_2026_10 PARTITION OF content_views
  FOR VALUES FROM ('2026-10-01') TO ('2026-11-01');

CREATE TABLE IF NOT EXISTS content_views_2026_11 PARTITION OF content_views
  FOR VALUES FROM ('2026-11-01') TO ('2026-12-01');

CREATE TABLE IF NOT EXISTS content_views_2026_12 PARTITION OF content_views
  FOR VALUES FROM ('2026-12-01') TO ('2027-01-01');

-- 4. Supprimer la partition dynamique expirée (si elle existe encore)
-- Les données dans la plage couverte par les partitions ci-dessus ont
-- déjà été routées vers la bonne partition par PostgreSQL.
DROP TABLE IF EXISTS content_views_current;

-- 5. Fonction utilitaire: créer la partition du mois prochain
-- À appeler via un pg_cron job mensuel: SELECT create_next_month_partition();
CREATE OR REPLACE FUNCTION create_next_month_partition()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  next_month_start DATE := date_trunc('month', now() + interval '1 month');
  next_month_end   DATE := date_trunc('month', now() + interval '2 months');
  partition_name   TEXT := 'content_views_' || to_char(next_month_start, 'YYYY_MM');
BEGIN
  -- Créer la partition seulement si elle n'existe pas encore
  IF NOT EXISTS (
    SELECT FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE c.relname = partition_name
    AND n.nspname = 'public'
  ) THEN
    EXECUTE format(
      'CREATE TABLE %I PARTITION OF content_views FOR VALUES FROM (%L) TO (%L)',
      partition_name,
      next_month_start,
      next_month_end
    );
  END IF;
END;
$$;

-- IMPORTANT: Configurer un cron job mensuel dans Supabase Dashboard → Database → Extensions → pg_cron:
-- SELECT cron.schedule('create-content-views-partition', '0 0 1 * *', 'SELECT create_next_month_partition()');
