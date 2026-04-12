-- Chat Service Schema

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
    room_id   UUID NOT NULL REFERENCES chat.chat_rooms(id) ON DELETE CASCADE,
    user_id   UUID NOT NULL,
    joined_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (room_id, user_id)
);

CREATE TABLE chat.messages (
    id        UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    room_id   UUID        NOT NULL REFERENCES chat.chat_rooms(id) ON DELETE CASCADE,
    sender_id UUID        NOT NULL,
    content   TEXT        NOT NULL,
    type      VARCHAR(20) NOT NULL DEFAULT 'TEXT'
                  CHECK (type IN ('TEXT','IMAGE','EMOJI','SYSTEM','GAME_INVITE')),
    media_url TEXT,
    deleted   BOOLEAN     NOT NULL DEFAULT FALSE,
    moderated BOOLEAN     NOT NULL DEFAULT FALSE,
    sent_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE chat.message_reads (
    message_id UUID NOT NULL REFERENCES chat.messages(id) ON DELETE CASCADE,
    user_id    UUID NOT NULL,
    read_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (message_id, user_id)
);

CREATE INDEX idx_messages_room    ON chat.messages(room_id, sent_at DESC);
CREATE INDEX idx_messages_sender  ON chat.messages(sender_id);
CREATE INDEX idx_room_members_user ON chat.chat_room_members(user_id);
