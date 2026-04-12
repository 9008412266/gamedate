-- Auth Service Database Schema
-- V1: Initial schema creation

CREATE SCHEMA IF NOT EXISTS auth;

CREATE TABLE auth.users (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email           VARCHAR(255) NOT NULL UNIQUE,
    username        VARCHAR(50)  NOT NULL UNIQUE,
    password_hash   VARCHAR(255) NOT NULL,
    phone_number    VARCHAR(20)  NOT NULL,
    age             INTEGER      NOT NULL CHECK (age >= 18),
    status          VARCHAR(30)  NOT NULL DEFAULT 'PENDING_VERIFICATION',
    provider        VARCHAR(20)  NOT NULL DEFAULT 'LOCAL',
    provider_id     VARCHAR(255),
    email_verified  BOOLEAN      NOT NULL DEFAULT FALSE,

    -- OTP fields
    verification_code        VARCHAR(6),
    verification_code_expiry TIMESTAMPTZ,

    -- Password reset
    password_reset_token  VARCHAR(255),
    password_reset_expiry TIMESTAMPTZ,

    -- Audit
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
    token        VARCHAR(512) NOT NULL UNIQUE,
    expires_at   TIMESTAMPTZ  NOT NULL,
    device_info  VARCHAR(255),
    ip_address   VARCHAR(45),
    revoked      BOOLEAN      NOT NULL DEFAULT FALSE,
    created_at   TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX idx_users_email         ON auth.users(email);
CREATE INDEX idx_users_username      ON auth.users(username);
CREATE INDEX idx_users_status        ON auth.users(status);
CREATE INDEX idx_refresh_tokens_user ON auth.refresh_tokens(user_id);
CREATE INDEX idx_refresh_tokens_exp  ON auth.refresh_tokens(expires_at);

-- Auto-update updated_at
CREATE OR REPLACE FUNCTION auth.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_users_updated_at
    BEFORE UPDATE ON auth.users
    FOR EACH ROW EXECUTE FUNCTION auth.update_updated_at_column();
