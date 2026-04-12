# 🎮❤️ GameDate Platform

> **Play Together, Connect Together** — A social gaming + dating app where you can play Ludo, Chess, and Billiards, match with people, chat, and make real connections.

---

## 📦 What's Built

```
109 files across 7 microservices + Flutter app + full infrastructure
```

### Backend (Spring Boot 3.2 / Java 17)
| Service | Port | Responsibility |
|---------|------|----------------|
| `api-gateway` | 8080 | JWT auth, routing, rate limiting, circuit breaker |
| `auth-service` | 8081 | Register (18+), login, OTP email verify, JWT + refresh tokens |
| `user-service` | 8082 | Profiles, swipe matching, proximity discovery, blocks/reports |
| `game-service` | 8083 | Ludo + Chess engines, AI (Easy/Medium/Hard), WebSocket rooms |
| `chat-service` | 8084 | Real-time chat, WebRTC voice/video signaling, content moderation |
| `wallet-service` | 8085 | Coin balance, transactions, daily rewards, subscriptions |
| `notification-service` | 8086 | Firebase FCM push notifications |

### Frontend (Flutter 3.19)
- Login / Register / Email OTP verification
- Discover page — Tinder-style card swiping
- Game lobby — Choose CHESS, LUDO, BILLIARDS, CARROM
- Real-time game room — WebSocket + STOMP
- WebRTC voice & video calling
- Match overlay animation
- Dark + Light theme

### Infrastructure
- `docker-compose.yml` — One-command local setup
- `Dockerfile` — Multi-stage builds for each service
- `terraform/main.tf` — AWS VPC, ECS, RDS, ElastiCache, S3, CloudFront
- `nginx.conf` — Reverse proxy with rate limiting + WebSocket support
- `.github/workflows/ci-cd.yml` — Full CI/CD: test → build → push ECR → deploy ECS

### Database
- `V1__complete_schema.sql` — Full PostgreSQL schema (all 6 schemas + indexes + triggers)
- `V2__sample_data.sql` — 5 test users with profiles, matches, chat, and wallets

---

## 🚀 Quick Start

```bash
# 1. Start infrastructure
docker-compose up -d postgres redis

# 2. Run any service
cd backend/auth-service
mvn spring-boot:run

# 3. Or run everything
docker-compose up -d

# 4. Flutter app
cd frontend/flutter-app
flutter run
```

Full instructions: [docs/SETUP.md](docs/SETUP.md)

---

## 🏗️ Architecture Highlights

- **Database-per-Service** pattern — each service owns its schema
- **JWT passed as headers** — API Gateway validates once, injects `X-User-Id`
- **Redis for everything real-time** — game state, presence, rate limits, daily counters
- **WebRTC signaling over STOMP** — voice/video calls use existing WebSocket
- **Minimax + alpha-beta pruning** — Chess AI at depth 4
- **Optimistic locking** — Wallet service prevents coin double-spend
- **Flyway migrations** — Schema versioned per service
- **Content moderation** — Bad word filter + phone/email masking in chat
- **Age gate** — 18+ enforced at DB level (`CHECK age >= 18`)

---

## 🔑 Default Test Credentials

After loading seed data:

| User | Email | Password |
|------|-------|----------|
| Alice | alice@example.com | Password1! |
| Bob | bob@example.com | Password1! |
| Charlie | charlie@example.com | Password1! |

---

## 📚 Key Files

| File | Purpose |
|------|---------|
| `docs/ARCHITECTURE.md` | ASCII system diagram + data flow |
| `docs/SETUP.md` | Local + AWS deployment guide |
| `docker-compose.yml` | Full local stack |
| `database/migrations/V1__complete_schema.sql` | Complete DB schema |
| `infrastructure/terraform/main.tf` | AWS Terraform |
| `.github/workflows/ci-cd.yml` | GitHub Actions CI/CD |
| `backend/game-service/.../ChessEngine.java` | Full chess logic |
| `backend/game-service/.../LudoEngine.java` | Full Ludo logic |
| `backend/game-service/.../AiOpponent.java` | AI with minimax |
| `backend/chat-service/.../ChatWebSocketHandler.java` | Chat + WebRTC signaling |
| `frontend/flutter-app/lib/features/chat/.../call_page.dart` | Voice/Video call UI |
