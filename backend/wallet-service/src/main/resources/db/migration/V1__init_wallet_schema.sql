-- Wallet Service Schema

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
    version                  BIGINT NOT NULL DEFAULT 0,
    updated_at               TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE wallet.transactions (
    id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id        UUID        NOT NULL,
    amount         BIGINT      NOT NULL,
    balance_after  BIGINT      NOT NULL,
    type           VARCHAR(30) NOT NULL,
    description    TEXT,
    reference_id   VARCHAR(255),
    created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE wallet.subscriptions (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id     UUID        NOT NULL,
    tier        VARCHAR(20) NOT NULL,
    store       VARCHAR(20) NOT NULL CHECK (store IN ('GOOGLE_PLAY','APP_STORE','WEB')),
    purchase_token TEXT NOT NULL,
    starts_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    expires_at  TIMESTAMPTZ NOT NULL,
    active      BOOLEAN NOT NULL DEFAULT TRUE,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_transactions_user ON wallet.transactions(user_id, created_at DESC);
CREATE INDEX idx_subscriptions_user ON wallet.subscriptions(user_id);
