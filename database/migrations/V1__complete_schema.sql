-- ============================================================
-- GameDate Platform — Complete Database Schema
-- PostgreSQL 15+
-- ============================================================

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";    -- For text search
CREATE EXTENSION IF NOT EXISTS "cube";        -- For earth_distance
CREATE EXTENSION IF NOT EXISTS "earthdistance"; -- For proximity queries

-- ============================================================
-- SCHEMA: auth
-- ============================================================
CREATE SCHEMA IF NOT EXISTS auth;

CREATE TABLE auth.users (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email           VARCHAR(255) NOT NULL UNIQUE,
    username        VARCHAR(50)  NOT NULL UNIQUE,
    password_hash   VARCHAR(255) NOT NULL,
    phone_number    VARCHAR(20)  NOT NULL,
    age             INTEGER      NOT NULL CHECK (age >= 18),
    status          VARCHAR(30)  NOT NULL DEFAULT 'PENDING_VERIFICATION'
                        CHECK (status IN ('PENDING_VERIFICATION','ACTIVE','SUSPENDED','BANNED','DELETED')),
    provider        VARCHAR(20)  NOT NULL DEFAULT 'LOCAL'
                        CHECK (provider IN ('LOCAL','GOOGLE','APPLE','FACEBOOK')),
    provider_id     VARCHAR(255),
    email_verified  BOOLEAN      NOT NULL DEFAULT FALSE,
    verification_code        VARCHAR(6),
    verification_code_expiry TIMESTAMPTZ,
    password_reset_token  VARCHAR(255) UNIQUE,
    password_reset_expiry TIMESTAMPTZ,
    last_login_at   TIMESTAMPTZ,
    last_login_ip   VARCHAR(45),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE auth.user_roles (
    user_id UUID        NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    role    VARCHAR(50) NOT NULL,
    PRIMARY KEY (user_id, role)
);

CREATE TABLE auth.refresh_tokens (
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id      UUID         NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    token        TEXT         NOT NULL UNIQUE,
    expires_at   TIMESTAMPTZ  NOT NULL,
    device_info  VARCHAR(255),
    ip_address   VARCHAR(45),
    revoked      BOOLEAN      NOT NULL DEFAULT FALSE,
    created_at   TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

-- ============================================================
-- SCHEMA: users
-- ============================================================
CREATE SCHEMA IF NOT EXISTS users;

CREATE TABLE users.user_profiles (
    user_id             UUID PRIMARY KEY,  -- Mirrors auth.users.id
    username            VARCHAR(50)  NOT NULL UNIQUE,
    display_name        VARCHAR(100) NOT NULL,
    bio                 TEXT,
    age                 INTEGER NOT NULL CHECK (age >= 18),
    gender              VARCHAR(20) NOT NULL
                            CHECK (gender IN ('MALE','FEMALE','NON_BINARY','PREFER_NOT_TO_SAY')),
    gender_preference   VARCHAR(20) NOT NULL DEFAULT 'ALL'
                            CHECK (gender_preference IN ('MALE','FEMALE','NON_BINARY','ALL')),
    latitude            DOUBLE PRECISION,
    longitude           DOUBLE PRECISION,
    city                VARCHAR(100),
    country             VARCHAR(50),
    profile_photo_url   TEXT,
    match_radius        INTEGER NOT NULL DEFAULT 50,
    is_online           BOOLEAN NOT NULL DEFAULT FALSE,
    last_seen_at        TIMESTAMPTZ,
    status              VARCHAR(20) NOT NULL DEFAULT 'ACTIVE'
                            CHECK (status IN ('ACTIVE','PAUSED','DELETED')),
    total_games_played  INTEGER NOT NULL DEFAULT 0,
    total_games_won     INTEGER NOT NULL DEFAULT 0,
    rating              INTEGER NOT NULL DEFAULT 1200,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE users.user_photos (
    id        UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id   UUID NOT NULL REFERENCES users.user_profiles(user_id) ON DELETE CASCADE,
    photo_url TEXT NOT NULL,
    sort_order INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE users.user_interests (
    user_id  UUID        NOT NULL REFERENCES users.user_profiles(user_id) ON DELETE CASCADE,
    interest VARCHAR(50) NOT NULL,
    PRIMARY KEY (user_id, interest)
);

CREATE TABLE users.user_game_preferences (
    user_id   UUID        NOT NULL REFERENCES users.user_profiles(user_id) ON DELETE CASCADE,
    game_type VARCHAR(20) NOT NULL,
    PRIMARY KEY (user_id, game_type)
);

CREATE TABLE users.swipes (
    id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    swiper_id  UUID NOT NULL,
    swiped_id  UUID NOT NULL,
    type       VARCHAR(20) NOT NULL CHECK (type IN ('LIKE','DISLIKE','SUPER_LIKE')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (swiper_id, swiped_id)
);

CREATE TABLE users.matches (
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user1_id     UUID        NOT NULL,
    user2_id     UUID        NOT NULL,
    chat_room_id UUID,
    status       VARCHAR(20) NOT NULL DEFAULT 'ACTIVE'
                     CHECK (status IN ('ACTIVE','UNMATCHED','BLOCKED')),
    matched_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CHECK (user1_id < user2_id) -- Ensures no duplicate pairs
);

CREATE TABLE users.blocks (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    blocker_id  UUID NOT NULL,
    blocked_id  UUID NOT NULL,
    reason      TEXT,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (blocker_id, blocked_id)
);

CREATE TABLE users.reports (
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    reporter_id  UUID        NOT NULL,
    reported_id  UUID        NOT NULL,
    reason       VARCHAR(50) NOT NULL,
    description  TEXT,
    status       VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    reviewed_by  UUID,
    created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================
-- SCHEMA: game
-- ============================================================
CREATE SCHEMA IF NOT EXISTS game;

CREATE TABLE game.game_rooms (
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    game_type    VARCHAR(20) NOT NULL CHECK (game_type IN ('LUDO','CHESS','BILLIARDS','CARROM')),
    status       VARCHAR(20) NOT NULL DEFAULT 'WAITING'
                     CHECK (status IN ('WAITING','STARTING','IN_PROGRESS','COMPLETED','ABANDONED','CANCELLED')),
    max_players  INTEGER     NOT NULL,
    player_ids   JSONB       NOT NULL DEFAULT '[]',
    winner_id    UUID,
    move_history JSONB       NOT NULL DEFAULT '[]',
    room_type    VARCHAR(20) NOT NULL DEFAULT 'PUBLIC'
                     CHECK (room_type IN ('PUBLIC','PRIVATE','AI_OPPONENT')),
    invite_code  VARCHAR(20) UNIQUE,
    coins_bet    INTEGER     NOT NULL DEFAULT 0,
    started_at   TIMESTAMPTZ,
    ended_at     TIMESTAMPTZ,
    created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE game.game_stats (
    user_id          UUID PRIMARY KEY,
    total_played     INTEGER NOT NULL DEFAULT 0,
    total_won        INTEGER NOT NULL DEFAULT 0,
    total_lost       INTEGER NOT NULL DEFAULT 0,
    total_drawn      INTEGER NOT NULL DEFAULT 0,
    ludo_played      INTEGER NOT NULL DEFAULT 0,
    ludo_won         INTEGER NOT NULL DEFAULT 0,
    chess_played     INTEGER NOT NULL DEFAULT 0,
    chess_won        INTEGER NOT NULL DEFAULT 0,
    billiards_played INTEGER NOT NULL DEFAULT 0,
    billiards_won    INTEGER NOT NULL DEFAULT 0,
    current_streak   INTEGER NOT NULL DEFAULT 0,
    longest_streak   INTEGER NOT NULL DEFAULT 0,
    elo_rating       INTEGER NOT NULL DEFAULT 1200,
    coins_earned     BIGINT  NOT NULL DEFAULT 0,
    updated_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================
-- SCHEMA: chat
-- ============================================================
CREATE SCHEMA IF NOT EXISTS chat;

CREATE TABLE chat.chat_rooms (
    id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    type       VARCHAR(20) NOT NULL CHECK (type IN ('DIRECT','GROUP','GAME_LOBBY')),
    name       VARCHAR(100),
    match_id   UUID,
    active     BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE chat.chat_room_members (
    room_id    UUID NOT NULL REFERENCES chat.chat_rooms(id) ON DELETE CASCADE,
    user_id    UUID NOT NULL,
    joined_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (room_id, user_id)
);

CREATE TABLE chat.messages (
    id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    room_id    UUID        NOT NULL REFERENCES chat.chat_rooms(id) ON DELETE CASCADE,
    sender_id  UUID        NOT NULL,
    content    TEXT        NOT NULL,
    type       VARCHAR(20) NOT NULL DEFAULT 'TEXT'
                   CHECK (type IN ('TEXT','IMAGE','EMOJI','SYSTEM','GAME_INVITE')),
    media_url  TEXT,
    deleted    BOOLEAN     NOT NULL DEFAULT FALSE,
    moderated  BOOLEAN     NOT NULL DEFAULT FALSE,
    sent_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE chat.message_reads (
    message_id UUID NOT NULL REFERENCES chat.messages(id) ON DELETE CASCADE,
    user_id    UUID NOT NULL,
    read_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (message_id, user_id)
);

-- ============================================================
-- SCHEMA: wallet
-- ============================================================
CREATE SCHEMA IF NOT EXISTS wallet;

CREATE TABLE wallet.wallets (
    user_id                  UUID PRIMARY KEY,
    coin_balance             BIGINT NOT NULL DEFAULT 0 CHECK (coin_balance >= 0),
    total_earned             BIGINT NOT NULL DEFAULT 0,
    total_spent              BIGINT NOT NULL DEFAULT 0,
    subscription_tier        VARCHAR(20) NOT NULL DEFAULT 'FREE'
                                 CHECK (subscription_tier IN ('FREE','PREMIUM','VIP')),
    subscription_expires_at  TIMESTAMPTZ,
    last_daily_reward_at     TIMESTAMPTZ,
    daily_reward_streak      INTEGER NOT NULL DEFAULT 0,
    version                  BIGINT NOT NULL DEFAULT 0, -- Optimistic locking
    updated_at               TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE wallet.transactions (
    id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id        UUID        NOT NULL,
    amount         BIGINT      NOT NULL, -- Positive = credit, negative = debit
    balance_after  BIGINT      NOT NULL,
    type           VARCHAR(30) NOT NULL,
    description    TEXT,
    reference_id   VARCHAR(255),
    created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================
-- SCHEMA: notification
-- ============================================================
CREATE SCHEMA IF NOT EXISTS notification;

CREATE TABLE notification.device_tokens (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id     UUID        NOT NULL,
    fcm_token   TEXT        NOT NULL UNIQUE,
    device_type VARCHAR(20) NOT NULL CHECK (device_type IN ('ANDROID','IOS')),
    active      BOOLEAN     NOT NULL DEFAULT TRUE,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE notification.notification_log (
    id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id    UUID        NOT NULL,
    type       VARCHAR(50) NOT NULL,
    title      TEXT        NOT NULL,
    body       TEXT        NOT NULL,
    data       JSONB,
    sent       BOOLEAN     NOT NULL DEFAULT FALSE,
    read       BOOLEAN     NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================
-- LEADERBOARD VIEW
-- ============================================================
CREATE OR REPLACE VIEW game.leaderboard AS
SELECT
    s.user_id,
    s.elo_rating,
    s.total_won,
    s.total_played,
    ROUND(CASE WHEN s.total_played > 0
        THEN (s.total_won::NUMERIC / s.total_played) * 100
        ELSE 0 END, 1) AS win_rate,
    s.longest_streak,
    s.coins_earned,
    RANK() OVER (ORDER BY s.elo_rating DESC) AS rank
FROM game.game_stats s
WHERE s.total_played >= 5  -- Minimum games to appear on leaderboard
ORDER BY s.elo_rating DESC;

-- ============================================================
-- INDEXES
-- ============================================================

-- Auth
CREATE INDEX idx_auth_users_email    ON auth.users(email);
CREATE INDEX idx_auth_users_username ON auth.users(username);
CREATE INDEX idx_refresh_tokens_user ON auth.refresh_tokens(user_id);

-- Users
CREATE INDEX idx_profiles_location   ON users.user_profiles(latitude, longitude);
CREATE INDEX idx_profiles_status     ON users.user_profiles(status);
CREATE INDEX idx_profiles_online     ON users.user_profiles(is_online);
CREATE INDEX idx_swipes_swiper       ON users.swipes(swiper_id, created_at DESC);
CREATE INDEX idx_swipes_swiped       ON users.swipes(swiped_id);
CREATE INDEX idx_matches_user1       ON users.matches(user1_id);
CREATE INDEX idx_matches_user2       ON users.matches(user2_id);

-- Game
CREATE INDEX idx_game_rooms_status   ON game.game_rooms(status, game_type);
CREATE INDEX idx_game_rooms_players  ON game.game_rooms USING gin(player_ids);

-- Chat
CREATE INDEX idx_messages_room       ON chat.messages(room_id, sent_at DESC);
CREATE INDEX idx_messages_sender     ON chat.messages(sender_id);

-- Wallet
CREATE INDEX idx_transactions_user   ON wallet.transactions(user_id, created_at DESC);

-- Notifications
CREATE INDEX idx_notif_user          ON notification.notification_log(user_id, created_at DESC);
CREATE INDEX idx_device_tokens_user  ON notification.device_tokens(user_id);

-- ============================================================
-- AUTO-UPDATE TRIGGERS
-- ============================================================
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN NEW.updated_at = NOW(); RETURN NEW; END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_auth_users_updated_at
    BEFORE UPDATE ON auth.users FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER trg_user_profiles_updated_at
    BEFORE UPDATE ON users.user_profiles FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER trg_game_rooms_updated_at
    BEFORE UPDATE ON game.game_rooms FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER trg_wallet_updated_at
    BEFORE UPDATE ON wallet.wallets FOR EACH ROW EXECUTE FUNCTION update_updated_at();
