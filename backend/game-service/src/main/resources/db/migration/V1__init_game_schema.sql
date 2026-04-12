-- Game Service Schema

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

-- Leaderboard view
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
WHERE s.total_played >= 5
ORDER BY s.elo_rating DESC;

CREATE INDEX idx_game_rooms_status  ON game.game_rooms(status, game_type);
CREATE INDEX idx_game_rooms_created ON game.game_rooms(created_at DESC);

CREATE OR REPLACE FUNCTION game.update_updated_at()
RETURNS TRIGGER AS $$
BEGIN NEW.updated_at = NOW(); RETURN NEW; END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_game_rooms_updated_at
    BEFORE UPDATE ON game.game_rooms
    FOR EACH ROW EXECUTE FUNCTION game.update_updated_at();
