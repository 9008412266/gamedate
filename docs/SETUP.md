# 🚀 Playraze Platform — Setup Guide

## Prerequisites

| Tool        | Version  | Install |
|-------------|----------|---------|
| Java        | 17+      | `brew install openjdk@17` |
| Maven       | 3.9+     | `brew install maven` |
| Docker      | 24+      | [docker.com](https://docker.com) |
| Flutter     | 3.19+    | [flutter.dev](https://flutter.dev) |
| Node.js     | 20+ (optional, for tools) | `brew install node` |
| AWS CLI     | 2.x      | `brew install awscli` |
| Terraform   | 1.6+     | `brew install terraform` |

---

## 🏠 Local Development

### 1. Clone & Setup

```bash
git clone https://github.com/your-org/playraze.git
cd playraze

# Copy env template
cp .env.example .env
# Edit .env with your credentials
```

### 2. Start Infrastructure Only

```bash
# Start PostgreSQL + Redis
docker-compose up -d postgres redis

# Verify health
docker-compose ps
```

### 3. Run Services Locally (Development Mode)

Each service can be started independently:

```bash
# Auth Service
cd backend/auth-service
mvn spring-boot:run -Dspring-boot.run.profiles=local

# User Service (new terminal)
cd backend/user-service
mvn spring-boot:run -Dspring-boot.run.profiles=local

# Game Service
cd backend/game-service
mvn spring-boot:run -Dspring-boot.run.profiles=local

# Chat Service
cd backend/chat-service
mvn spring-boot:run -Dspring-boot.run.profiles=local

# Wallet Service
cd backend/wallet-service
mvn spring-boot:run -Dspring-boot.run.profiles=local

# API Gateway (start last)
cd backend/api-gateway
mvn spring-boot:run -Dspring-boot.run.profiles=local
```

### 4. Start Everything with Docker Compose

```bash
# Build all images
docker-compose build

# Start all services
docker-compose up -d

# Check logs
docker-compose logs -f

# Stop all
docker-compose down
```

### 5. Load Sample Data

```bash
# Connect to PostgreSQL
psql -h localhost -U playraze -d playraze

# Run seed data
\i database/seeds/V2__sample_data.sql

# Or with psql directly:
PGPASSWORD=playraze123 psql -h localhost -U playraze -d playraze \
  -f database/seeds/V2__sample_data.sql
```

### 6. Run Flutter App

```bash
cd frontend/flutter-app

# Install dependencies
flutter pub get

# Run on iOS simulator
flutter run -d ios

# Run on Android emulator
flutter run -d android

# Run on Chrome (web)
flutter run -d chrome
```

---

## 🔑 Environment Variables

Create `.env` in project root:

```env
# Database
DB_URL=jdbc:postgresql://localhost:5432/playraze
DB_USERNAME=playraze
DB_PASSWORD=playraze123

# Redis
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_PASSWORD=redis123

# JWT (generate with: openssl rand -base64 64)
JWT_SECRET=your-super-secret-jwt-key-minimum-32-characters-long

# Email (Gmail SMTP example)
MAIL_HOST=smtp.gmail.com
MAIL_PORT=587
MAIL_USERNAME=your-email@gmail.com
MAIL_PASSWORD=your-app-password
MAIL_FROM=noreply@playraze.app

# AWS (for S3 media storage)
AWS_REGION=us-east-1
AWS_ACCESS_KEY_ID=your-access-key
AWS_SECRET_ACCESS_KEY=your-secret-key
AWS_S3_BUCKET=playraze-media-dev
AWS_CLOUDFRONT_DOMAIN=your-cloudfront-domain.cloudfront.net

# Firebase (for push notifications)
FCM_SERVER_KEY=your-fcm-server-key

# Frontend
FRONTEND_URL=https://playraze.app
```

---

## 🌐 API Documentation

Once running, Swagger UI is available at:

- Gateway:           http://localhost:8080/swagger-ui.html
- Auth Service:      http://localhost:8081/swagger-ui.html
- User Service:      http://localhost:8082/swagger-ui.html
- Game Service:      http://localhost:8083/swagger-ui.html
- Chat Service:      http://localhost:8084/swagger-ui.html
- Wallet Service:    http://localhost:8085/swagger-ui.html

---

## ☁️ AWS Deployment

### Prerequisites

```bash
# Configure AWS CLI
aws configure

# Install Terraform
brew install terraform

# Create S3 bucket for Terraform state
aws s3 mb s3://playraze-terraform-state --region us-east-1
```

### 1. Create ECR Repositories

```bash
services=("api-gateway" "auth-service" "user-service" "game-service" "chat-service" "wallet-service" "notification-service")
for service in "${services[@]}"; do
  aws ecr create-repository --repository-name "playraze-$service" --region us-east-1
done
```

### 2. Provision Infrastructure

```bash
cd infrastructure/terraform

terraform init

terraform plan -var="db_password=YourSecurePassword123" \
               -var="jwt_secret=YourJwtSecret"

terraform apply -var="db_password=YourSecurePassword123" \
                -var="jwt_secret=YourJwtSecret"
```

### 3. Set GitHub Secrets

In your GitHub repository settings, add:

```
AWS_ACCOUNT_ID
AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY
PRIVATE_SUBNET_IDS
ECS_SECURITY_GROUP
SLACK_WEBHOOK
```

### 4. Push to Deploy

```bash
# Push to develop for staging deployment
git push origin develop

# Push to main for production (requires approval)
git push origin main
```

---

## 🧪 Testing

### Backend Tests

```bash
# Run all tests
cd backend/auth-service && mvn test

# Run specific test class
mvn test -Dtest=AuthServiceTest

# Run with coverage report
mvn test jacoco:report
```

### Flutter Tests

```bash
cd frontend/flutter-app

# Unit tests
flutter test

# Integration tests
flutter test integration_test/

# Widget tests with coverage
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
```

---

## 📱 Building Release Apps

### Android APK

```bash
cd frontend/flutter-app

# Generate signing key (first time only)
keytool -genkey -v -keystore android/app/playraze.keystore \
  -keyalg RSA -keysize 2048 -validity 10000 -alias playraze

# Build release APK
flutter build apk --release

# Build App Bundle (for Play Store)
flutter build appbundle --release
```

### iOS IPA

```bash
# Requires Xcode and Apple Developer account
flutter build ios --release
# Then archive in Xcode and upload to App Store Connect
```

---

## 🔍 Monitoring & Troubleshooting

```bash
# Check service health
curl http://localhost:8080/actuator/health

# View service logs
docker-compose logs -f auth-service

# Monitor Redis
redis-cli -h localhost -a redis123 monitor

# PostgreSQL active connections
psql -h localhost -U playraze -c "SELECT * FROM pg_stat_activity;"

# Check game state in Redis
redis-cli -h localhost -a redis123 keys "game:state:*"
```

---

## 🏗️ Architecture Decisions

| Decision | Choice | Reason |
|----------|--------|--------|
| Backend | Spring Boot 3.2 + Java 17 | Production-proven, virtual threads support |
| Gateway | Spring Cloud Gateway | Reactive, circuit breaker built-in |
| Real-time | WebSocket + STOMP | Works well with Spring, client libraries available |
| Voice/Video | WebRTC | Peer-to-peer, low latency, free |
| Signaling | STOMP over WS | Reuses existing WebSocket infrastructure |
| AI | Rule-based minimax | Predictable, fast, no external dependency |
| Mobile | Flutter | Single codebase for iOS + Android |
| State | BLoC + Equatable | Testable, predictable state management |
| DB | PostgreSQL | JSONB for flexible game state, PostGIS for location |
| Cache | Redis | Fast, pub/sub for real-time sync |
| Media | S3 + CloudFront | Scalable CDN, signed URLs for security |
