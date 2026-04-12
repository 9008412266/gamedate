-- ============================================================
-- Sample Test Data
-- Passwords are all bcrypt of "Password1!"
-- ============================================================

-- Auth Users
INSERT INTO auth.users (id, email, username, password_hash, phone_number, age, status, email_verified)
VALUES
  ('a0000000-0000-0000-0000-000000000001', 'alice@example.com',   'alice_gamer',  '$2a$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQyCsBBSJPxVUJhZvCdYj7JrS', '+1234567890', 25, 'ACTIVE', true),
  ('a0000000-0000-0000-0000-000000000002', 'bob@example.com',     'bob_plays',    '$2a$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQyCsBBSJPxVUJhZvCdYj7JrS', '+1234567891', 28, 'ACTIVE', true),
  ('a0000000-0000-0000-0000-000000000003', 'charlie@example.com', 'chess_master', '$2a$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQyCsBBSJPxVUJhZvCdYj7JrS', '+1234567892', 22, 'ACTIVE', true),
  ('a0000000-0000-0000-0000-000000000004', 'diana@example.com',   'ludo_queen',   '$2a$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQyCsBBSJPxVUJhZvCdYj7JrS', '+1234567893', 26, 'ACTIVE', true),
  ('a0000000-0000-0000-0000-000000000005', 'evan@example.com',    'evan_wins',    '$2a$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQyCsBBSJPxVUJhZvCdYj7JrS', '+1234567894', 30, 'ACTIVE', true);

INSERT INTO auth.user_roles (user_id, role)
VALUES
  ('a0000000-0000-0000-0000-000000000001', 'ROLE_USER'),
  ('a0000000-0000-0000-0000-000000000002', 'ROLE_USER'),
  ('a0000000-0000-0000-0000-000000000003', 'ROLE_USER'),
  ('a0000000-0000-0000-0000-000000000004', 'ROLE_USER'),
  ('a0000000-0000-0000-0000-000000000005', 'ROLE_USER');

-- User Profiles
INSERT INTO users.user_profiles (user_id, username, display_name, bio, age, gender, gender_preference, latitude, longitude, city, country, rating, total_games_played, total_games_won)
VALUES
  ('a0000000-0000-0000-0000-000000000001', 'alice_gamer', 'Alice', 'Chess enthusiast & Ludo champion 🎮', 25, 'FEMALE', 'MALE', 40.7128, -74.0060, 'New York', 'US', 1450, 42, 28),
  ('a0000000-0000-0000-0000-000000000002', 'bob_plays',   'Bob',   'I love strategy games! Ludo is life 🎲',  28, 'MALE', 'FEMALE', 40.7589, -73.9851, 'New York', 'US', 1320, 35, 19),
  ('a0000000-0000-0000-0000-000000000003', 'chess_master','Charlie','Grand master in the making ♟️',            22, 'MALE', 'ALL', 51.5074, -0.1278, 'London', 'UK', 1580, 67, 48),
  ('a0000000-0000-0000-0000-000000000004', 'ludo_queen',  'Diana', 'Ludo expert. Challenge me! 👑',           26, 'FEMALE', 'MALE', 48.8566, 2.3522, 'Paris', 'FR', 1390, 55, 35),
  ('a0000000-0000-0000-0000-000000000005', 'evan_wins',   'Evan',  'Casual gamer, serious about fun 🎯',      30, 'MALE', 'FEMALE', 34.0522, -118.2437, 'LA', 'US', 1250, 20, 10);

-- Interests
INSERT INTO users.user_interests (user_id, interest)
VALUES
  ('a0000000-0000-0000-0000-000000000001', 'Chess'), ('a0000000-0000-0000-0000-000000000001', 'Movies'), ('a0000000-0000-0000-0000-000000000001', 'Hiking'),
  ('a0000000-0000-0000-0000-000000000002', 'Ludo'), ('a0000000-0000-0000-0000-000000000002', 'Music'), ('a0000000-0000-0000-0000-000000000002', 'Travel'),
  ('a0000000-0000-0000-0000-000000000003', 'Chess'), ('a0000000-0000-0000-0000-000000000003', 'Reading'), ('a0000000-0000-0000-0000-000000000003', 'Coding'),
  ('a0000000-0000-0000-0000-000000000004', 'Ludo'), ('a0000000-0000-0000-0000-000000000004', 'Cooking'), ('a0000000-0000-0000-0000-000000000004', 'Yoga'),
  ('a0000000-0000-0000-0000-000000000005', 'Billiards'), ('a0000000-0000-0000-0000-000000000005', 'Sports'), ('a0000000-0000-0000-0000-000000000005', 'Gaming');

-- Wallets (with welcome bonus coins)
INSERT INTO wallet.wallets (user_id, coin_balance, total_earned, daily_reward_streak)
VALUES
  ('a0000000-0000-0000-0000-000000000001', 580, 680, 7),
  ('a0000000-0000-0000-0000-000000000002', 320, 420, 3),
  ('a0000000-0000-0000-0000-000000000003', 1200, 1400, 14),
  ('a0000000-0000-0000-0000-000000000004', 750, 900, 5),
  ('a0000000-0000-0000-0000-000000000005', 100, 200, 1);

-- Game Stats
INSERT INTO game.game_stats (user_id, total_played, total_won, total_lost, ludo_played, ludo_won, chess_played, chess_won, elo_rating, coins_earned)
VALUES
  ('a0000000-0000-0000-0000-000000000001', 42, 28, 14, 20, 15, 22, 13, 1450, 1400),
  ('a0000000-0000-0000-0000-000000000002', 35, 19, 16, 30, 17, 5, 2,  1320, 950),
  ('a0000000-0000-0000-0000-000000000003', 67, 48, 19, 10, 6,  57, 42, 1580, 2400),
  ('a0000000-0000-0000-0000-000000000004', 55, 35, 20, 50, 33, 5, 2,  1390, 1750),
  ('a0000000-0000-0000-0000-000000000005', 20, 10, 10, 10, 5,  5, 3,  1250, 500);

-- A match between Alice and Bob
INSERT INTO users.matches (id, user1_id, user2_id, status)
VALUES ('m0000000-0000-0000-0000-000000000001',
        'a0000000-0000-0000-0000-000000000001',
        'a0000000-0000-0000-0000-000000000002',
        'ACTIVE');

-- A chat room for their match
INSERT INTO chat.chat_rooms (id, type, match_id)
VALUES ('c0000000-0000-0000-0000-000000000001', 'DIRECT', 'm0000000-0000-0000-0000-000000000001');

INSERT INTO chat.chat_room_members (room_id, user_id)
VALUES
  ('c0000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000001'),
  ('c0000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000002');

INSERT INTO chat.messages (room_id, sender_id, content, type)
VALUES
  ('c0000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000001', 'Hey! Want to play chess? 😊', 'TEXT'),
  ('c0000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000002', 'Sure! I''ll challenge you to Ludo first 😄', 'TEXT'),
  ('c0000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000001', 'You''re on! 🎲', 'TEXT');

-- Global chat room
INSERT INTO chat.chat_rooms (id, type, name) VALUES ('c0000000-0000-0000-0000-000000000002', 'GROUP', 'Global Chat 🌍');
