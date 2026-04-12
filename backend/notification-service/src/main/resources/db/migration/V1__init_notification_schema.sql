-- Notification Service Schema

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

CREATE INDEX idx_device_tokens_user ON notification.device_tokens(user_id);
CREATE INDEX idx_notif_user         ON notification.notification_log(user_id, created_at DESC);
CREATE INDEX idx_notif_unread       ON notification.notification_log(user_id, read) WHERE read = FALSE;
