-- User Service Schema
-- Requires: pg_trgm, earthdistance, cube extensions (in main DB migration)

CREATE SCHEMA IF NOT EXISTS users;

CREATE TABLE users.user_profiles (
    user_id             UUID PRIMARY KEY,
    username            VARCHAR(50)  NOT NULL UNIQUE,
    display_name        VARCHAR(100) NOT NULL,
    bio                 TEXT,
    age                 INTEGER NOT NULL CHECK (age >= 18),
    gender              VARCHAR(20) NOT NULL DEFAULT 'PREFER_NOT_TO_SAY'
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
    id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id    UUID NOT NULL REFERENCES users.user_profiles(user_id) ON DELETE CASCADE,
    photo_url  TEXT NOT NULL,
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
    UNIQUE (user1_id, user2_id)
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
    created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_profiles_location ON users.user_profiles(latitude, longitude);
CREATE INDEX idx_profiles_status   ON users.user_profiles(status);
CREATE INDEX idx_profiles_online   ON users.user_profiles(is_online);
CREATE INDEX idx_profiles_gender   ON users.user_profiles(gender, gender_preference);
CREATE INDEX idx_swipes_swiper     ON users.swipes(swiper_id);
CREATE INDEX idx_swipes_swiped     ON users.swipes(swiped_id);
CREATE INDEX idx_matches_user1     ON users.matches(user1_id);
CREATE INDEX idx_matches_user2     ON users.matches(user2_id);

-- Auto-update trigger
CREATE OR REPLACE FUNCTION users.update_updated_at()
RETURNS TRIGGER AS $$
BEGIN NEW.updated_at = NOW(); RETURN NEW; END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_profiles_updated_at
    BEFORE UPDATE ON users.user_profiles
    FOR EACH ROW EXECUTE FUNCTION users.update_updated_at();
