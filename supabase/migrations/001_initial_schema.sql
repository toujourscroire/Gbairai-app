-- ════════════════════════════════════════════════════════════════════
-- GBAIRAI — Migration 001 : Schéma initial
-- Version : 1.0.0 | Date : 2025-05-30
-- ════════════════════════════════════════════════════════════════════

-- Extension UUID
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ── UTILISATEURS ──────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS users (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  auth_id               UUID UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,
  phone                 TEXT UNIQUE,
  email                 TEXT UNIQUE,
  username              TEXT UNIQUE NOT NULL
                        CHECK (length(username) >= 3 AND length(username) <= 30
                               AND username ~ '^[a-zA-Z0-9_\-]+$'),
  created_at            TIMESTAMPTZ DEFAULT now(),
  updated_at            TIMESTAMPTZ DEFAULT now(),
  role                  TEXT DEFAULT 'user'
                        CHECK (role IN ('user','moderator','admin')),
  is_banned             BOOLEAN DEFAULT false,
  ban_until             TIMESTAMPTZ,
  anonymous_posts_count INT DEFAULT 0 CHECK (anonymous_posts_count >= 0),
  anonymous_reset_at    TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS profiles (
  user_id               UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  display_name          TEXT NOT NULL CHECK (length(display_name) <= 50),
  bio                   TEXT CHECK (length(bio) <= 150),
  avatar_url            TEXT,
  banner_url            TEXT,
  city                  TEXT DEFAULT 'Abidjan',
  level                 TEXT DEFAULT 'debutant'
                        CHECK (level IN ('debutant','influenceur','grand_patron','legende')),
  level_score           BIGINT DEFAULT 0 CHECK (level_score >= 0),
  followers_count       INT DEFAULT 0 CHECK (followers_count >= 0),
  following_count       INT DEFAULT 0 CHECK (following_count >= 0),
  posts_count           INT DEFAULT 0 CHECK (posts_count >= 0),
  is_verified           BOOLEAN DEFAULT false,
  is_business           BOOLEAN DEFAULT false,
  notification_pref     JSONB DEFAULT '{"alerts":"all","quiet_start":"23:00","quiet_end":"07:00","categories":[]}',
  fcm_token             TEXT,
  updated_at            TIMESTAMPTZ DEFAULT now()
);

-- Device fingerprints pour détection multi-comptes
CREATE TABLE IF NOT EXISTS device_fingerprints (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  fingerprint   TEXT NOT NULL,
  user_id       UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  platform      TEXT NOT NULL CHECK (platform IN ('ios','android')),
  created_at    TIMESTAMPTZ DEFAULT now(),
  UNIQUE (fingerprint, user_id)
);

-- Audit log sécurité
CREATE TABLE IF NOT EXISTS audit_logs (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID REFERENCES users(id),
  action      TEXT NOT NULL,
  target_type TEXT,
  target_id   UUID,
  ip_hash     TEXT, -- Hash de l'IP, jamais en clair
  user_agent  TEXT,
  metadata    JSONB DEFAULT '{}',
  created_at  TIMESTAMPTZ DEFAULT now()
);

-- ── CONTENUS ──────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS contents (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id               UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  type                  TEXT NOT NULL CHECK (type IN ('video','text','audio')),

  -- Médias
  media_url             TEXT,
  stream_id             TEXT, -- Cloudflare Stream ID
  thumbnail_url         TEXT,
  duration_seconds      FLOAT CHECK (duration_seconds > 0),

  -- Texte / Statut
  caption               TEXT CHECK (length(caption) <= 280),
  text_font             TEXT DEFAULT 'inter',
  text_size             TEXT DEFAULT 'normal' CHECK (text_size IN ('normal','large','xlarge')),
  text_background       TEXT DEFAULT 'gradient_1',

  -- Audio
  voice_title           TEXT CHECK (length(voice_title) <= 80),
  voice_cover_bg        TEXT DEFAULT 'orange',
  waveform_data         JSONB,

  -- Localisation
  city                  TEXT DEFAULT 'Abidjan',
  district              TEXT,

  -- Anonymat
  is_anonymous          BOOLEAN DEFAULT false,
  anon_username         TEXT CHECK (length(anon_username) <= 50),

  -- Visibilité
  visibility            TEXT DEFAULT 'public' CHECK (visibility IN ('public','followers')),

  -- Scoring
  score                 FLOAT DEFAULT 0 CHECK (score >= 0),
  score_adjusted        FLOAT DEFAULT 0 CHECK (score_adjusted >= 0),
  views_count           BIGINT DEFAULT 0 CHECK (views_count >= 0),
  reactions_count       BIGINT DEFAULT 0 CHECK (reactions_count >= 0),
  comments_count        BIGINT DEFAULT 0 CHECK (comments_count >= 0),
  shares_count          BIGINT DEFAULT 0 CHECK (shares_count >= 0),
  voice_reactions_count INT DEFAULT 0 CHECK (voice_reactions_count >= 0),
  gbairai_level         TEXT CHECK (gbairai_level IN ('pre_gbairai','local','national','legendaire')),

  -- Modération
  moderation_score      FLOAT CHECK (moderation_score BETWEEN 0 AND 1),
  moderation_status     TEXT DEFAULT 'pending'
                        CHECK (moderation_status IN ('pending','approved','review','rejected')),
  is_flagged            BOOLEAN DEFAULT false,
  flags_count           INT DEFAULT 0 CHECK (flags_count >= 0),
  is_fake_news_suspect  BOOLEAN DEFAULT false,

  -- Timestamps
  created_at            TIMESTAMPTZ DEFAULT now(),
  published_at          TIMESTAMPTZ,
  deleted_at            TIMESTAMPTZ
);

-- Index critiques pour les perfs
CREATE INDEX IF NOT EXISTS idx_contents_score ON contents(score_adjusted DESC NULLS LAST)
  WHERE deleted_at IS NULL AND moderation_status = 'approved' AND visibility = 'public';
CREATE INDEX IF NOT EXISTS idx_contents_user ON contents(user_id, created_at DESC)
  WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_contents_gbairai ON contents(gbairai_level)
  WHERE gbairai_level IS NOT NULL AND deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_contents_active ON contents(created_at DESC)
  WHERE deleted_at IS NULL AND moderation_status = 'approved';

-- ── RÉACTIONS ─────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS reactions (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  content_id      UUID NOT NULL REFERENCES contents(id) ON DELETE CASCADE,
  user_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  reaction_type   TEXT NOT NULL CHECK (reaction_type IN (
    'gbairai','on_a_ri','cest_vrai','wari_deh','dja','we_we'
  )),
  created_at      TIMESTAMPTZ DEFAULT now(),
  UNIQUE (content_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_reactions_content ON reactions(content_id, reaction_type);

-- ── RÉACTIONS VOCALES ─────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS voice_reactions (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  content_id      UUID NOT NULL REFERENCES contents(id) ON DELETE CASCADE,
  user_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  audio_url       TEXT NOT NULL,
  duration_seconds FLOAT NOT NULL CHECK (duration_seconds > 0 AND duration_seconds <= 30),
  waveform_data   JSONB,
  views_count     INT DEFAULT 0 CHECK (views_count >= 0),
  is_anonymous    BOOLEAN DEFAULT false,
  created_at      TIMESTAMPTZ DEFAULT now(),
  deleted_at      TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_voice_reactions_content ON voice_reactions(content_id, created_at DESC)
  WHERE deleted_at IS NULL;

-- ── COMMENTAIRES ──────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS comments (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  content_id      UUID NOT NULL REFERENCES contents(id) ON DELETE CASCADE,
  user_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  parent_id       UUID REFERENCES comments(id),
  body            TEXT NOT NULL CHECK (length(body) >= 1 AND length(body) <= 300),
  is_pinned       BOOLEAN DEFAULT false,
  is_flagged      BOOLEAN DEFAULT false,
  is_restricted   BOOLEAN DEFAULT false,
  moderation_score FLOAT CHECK (moderation_score BETWEEN 0 AND 1),
  created_at      TIMESTAMPTZ DEFAULT now(),
  deleted_at      TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_comments_content ON comments(content_id, created_at ASC)
  WHERE deleted_at IS NULL;

-- ── VUES ──────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS content_views (
  id              UUID DEFAULT gen_random_uuid(),
  content_id      UUID NOT NULL REFERENCES contents(id) ON DELETE CASCADE,
  user_id         UUID REFERENCES users(id),
  session_id      TEXT,
  watch_duration_seconds FLOAT,
  completed       BOOLEAN DEFAULT false,
  source          TEXT CHECK (source IN ('feed','alert','profile','trending','whatsapp','external')),
  created_at      TIMESTAMPTZ DEFAULT now(),
  PRIMARY KEY (id, created_at)
) PARTITION BY RANGE (created_at);

-- Partitions hebdomadaires pour les perfs
CREATE TABLE IF NOT EXISTS content_views_current PARTITION OF content_views
  FOR VALUES FROM (now() - interval '1 week') TO (now() + interval '1 week');

CREATE INDEX IF NOT EXISTS idx_views_content ON content_views(content_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_views_velocity ON content_views(content_id, created_at);

-- ── ALERTES GBAIRAI ───────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS gbairai_alerts (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  content_id      UUID NOT NULL REFERENCES contents(id),
  level           TEXT NOT NULL CHECK (level IN ('pre_gbairai','local','national','legendaire')),
  title_generated TEXT NOT NULL CHECK (length(title_generated) <= 200),
  triggered_at    TIMESTAMPTZ DEFAULT now(),
  sent_count      BIGINT DEFAULT 0 CHECK (sent_count >= 0),
  opened_count    BIGINT DEFAULT 0 CHECK (opened_count >= 0),
  open_rate       FLOAT CHECK (open_rate BETWEEN 0 AND 1),
  is_sponsored    BOOLEAN DEFAULT false,
  sponsor_id      UUID REFERENCES users(id),
  city_scope      TEXT,
  fcm_message_id  TEXT
);

CREATE INDEX IF NOT EXISTS idx_alerts_time ON gbairai_alerts(triggered_at DESC);
CREATE INDEX IF NOT EXISTS idx_alerts_content ON gbairai_alerts(content_id, level);

-- ── RELATIONS SOCIALES ────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS follows (
  follower_id     UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  following_id    UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  created_at      TIMESTAMPTZ DEFAULT now(),
  PRIMARY KEY (follower_id, following_id),
  CHECK (follower_id != following_id)
);

CREATE INDEX IF NOT EXISTS idx_follows_following ON follows(following_id);
CREATE INDEX IF NOT EXISTS idx_follows_follower ON follows(follower_id);

-- ── HASHTAGS ──────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS hashtags (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tag             TEXT UNIQUE NOT NULL
                  CHECK (length(tag) >= 2 AND length(tag) <= 50
                         AND tag ~ '^[a-zA-Z0-9_À-ÿ]+$'),
  uses_count      BIGINT DEFAULT 0 CHECK (uses_count >= 0),
  uses_last_hour  INT DEFAULT 0,
  uses_last_day   INT DEFAULT 0,
  trending_score  FLOAT DEFAULT 0,
  updated_at      TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS content_hashtags (
  content_id      UUID NOT NULL REFERENCES contents(id) ON DELETE CASCADE,
  hashtag_id      UUID NOT NULL REFERENCES hashtags(id) ON DELETE CASCADE,
  PRIMARY KEY (content_id, hashtag_id)
);

-- ── SIGNALEMENTS ──────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS reports (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  reporter_id     UUID NOT NULL REFERENCES users(id),
  target_type     TEXT NOT NULL CHECK (target_type IN ('content','comment','user','voice_reaction')),
  target_id       UUID NOT NULL,
  reason          TEXT NOT NULL CHECK (reason IN (
    'spam','violence','nudity','fake_news','harassment','hate_speech','other'
  )),
  detail          TEXT CHECK (length(detail) <= 500),
  status          TEXT DEFAULT 'pending'
                  CHECK (status IN ('pending','reviewed','actioned','dismissed')),
  reviewed_by     UUID REFERENCES users(id),
  created_at      TIMESTAMPTZ DEFAULT now()
);

-- ── BLOCAGES ──────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS blocks (
  blocker_id      UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  blocked_id      UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  created_at      TIMESTAMPTZ DEFAULT now(),
  PRIMARY KEY (blocker_id, blocked_id)
);

-- ── NOTIFICATIONS ─────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS notifications (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  type            TEXT NOT NULL CHECK (type IN (
    'alert','reaction','comment','follow','mention','voice_reaction'
  )),
  title           TEXT NOT NULL CHECK (length(title) <= 100),
  body            TEXT NOT NULL CHECK (length(body) <= 300),
  data            JSONB DEFAULT '{}',
  is_read         BOOLEAN DEFAULT false,
  deep_link       TEXT,
  created_at      TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_notifs_user ON notifications(user_id, created_at DESC)
  WHERE is_read = false;
