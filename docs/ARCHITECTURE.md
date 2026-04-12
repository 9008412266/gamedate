# 🏗️ System Architecture — Playraze Platform

## Overview

Playraze is a social gaming + dating platform built on microservices, capable of
serving millions of concurrent users. Below is the complete architectural blueprint.

---

## 🗺️ High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                            CLIENT LAYER                                     │
│   Flutter Mobile App (iOS/Android)   │   Web (Future)                      │
└──────────────────────────┬──────────────────────────────────────────────────┘
                           │ HTTPS / WSS
┌──────────────────────────▼──────────────────────────────────────────────────┐
│                        AWS CloudFront (CDN)                                 │
└──────────────────────────┬──────────────────────────────────────────────────┘
                           │
┌──────────────────────────▼──────────────────────────────────────────────────┐
│                     AWS Application Load Balancer                           │
└──────┬──────────────────────────────────────────────────────────────────────┘
       │
┌──────▼─────────────────────────────────────────────────────────────────────┐
│                        API GATEWAY (Spring Cloud Gateway)                  │
│   - Rate Limiting (Redis)     - JWT Validation                             │
│   - Request Routing           - CORS Handling                              │
│   - Load Balancing            - Circuit Breaker (Resilience4j)             │
└──────┬─────────┬─────────┬──────────┬─────────┬──────────┬────────────────┘
       │         │         │          │         │          │
┌──────▼──┐ ┌───▼───┐ ┌───▼────┐ ┌───▼───┐ ┌───▼───┐ ┌───▼──────────┐
│  AUTH   │ │ USER  │ │  GAME  │ │ CHAT  │ │WALLET │ │NOTIFICATION  │
│SERVICE  │ │SERVICE│ │SERVICE │ │SERVICE│ │SERVICE│ │  SERVICE     │
│:8081    │ │:8082  │ │:8083   │ │:8084  │ │:8085  │ │  :8086       │
└──────┬──┘ └───┬───┘ └───┬────┘ └───┬───┘ └───┬───┘ └───┬──────────┘
       │        │         │          │         │          │
┌──────▼────────▼─────────▼──────────▼─────────▼──────────▼──────────────────┐
│                          MESSAGE BUS (Redis Pub/Sub)                        │
└─────────────────────────────────────────────────────────────────────────────┘
       │                          │                    │
┌──────▼───────┐        ┌─────────▼──────┐   ┌────────▼────────┐
│  PostgreSQL  │        │     Redis      │   │    AWS S3       │
│  (Primary)   │        │ (Cache/Session)│   │ (Media Storage) │
│  RDS Multi-AZ│        │  Cluster       │   │  + CloudFront   │
└──────────────┘        └────────────────┘   └─────────────────┘
```

---

## 📦 Microservices Breakdown

| Service             | Port  | Responsibility                                         |
|---------------------|-------|--------------------------------------------------------|
| api-gateway         | 8080  | Routing, rate limiting, auth validation                |
| auth-service        | 8081  | Registration, login, JWT, OAuth2                       |
| user-service        | 8082  | Profiles, matching, friends, swipe system              |
| game-service        | 8083  | Game rooms, AI, real-time gameplay via WebSocket       |
| chat-service        | 8084  | Messaging, voice/video signaling via WebSocket         |
| wallet-service      | 8085  | Coins, transactions, rewards, subscriptions            |
| notification-service| 8086  | Push notifications, FCM, daily rewards, emails         |

---

## 🔄 Data Flow — Game Session

```
Client ──WebSocket──► API Gateway ──► Game Service
                                           │
                                    ┌──────▼────────┐
                                    │  Game Room    │
                                    │  (In-Memory)  │
                                    │  + Redis Sync │
                                    └──────┬────────┘
                                           │
                              ┌────────────┴───────────┐
                              │                        │
                         Human Player              AI Engine
                         (WebSocket)           (Rule-Based AI)
```

## 🔄 Data Flow — Matching System

```
User Swipes Right
      │
      ▼
User Service ──► Check if other user liked back (Redis cache)
      │
      ├─── NO MATCH: Store like in DB
      │
      └─── MATCH: 
            ├── Create chat room (Chat Service)
            ├── Send notification (Notification Service)  
            └── Award coins (Wallet Service)
```

---

## 🔐 Security Architecture

```
Request Flow:
1. Client sends JWT in Authorization header
2. API Gateway validates JWT signature
3. Extracts user claims
4. Forwards with X-User-Id header to service
5. Service uses X-User-Id (no re-validation needed)

JWT Structure:
{
  "sub": "user-uuid",
  "roles": ["USER"],
  "email": "user@example.com",
  "iat": 1234567890,
  "exp": 1234657890
}
```

---

## 🗄️ Database Design

Each service owns its own schema (Database-per-Service pattern):

- `auth_db` → auth-service
- `user_db` → user-service  
- `game_db` → game-service
- `chat_db` → chat-service
- `wallet_db` → wallet-service
- `notification_db` → notification-service

---

## ⚡ Real-Time Architecture

```
WebSocket Connections:
- /ws/game/{roomId}   → Game Service (STOMP over WebSocket)
- /ws/chat/{chatId}   → Chat Service (STOMP over WebSocket)
- /ws/signaling       → Chat Service (WebRTC signaling)

Redis Pub/Sub Channels:
- game:room:{id}      → Game state sync across instances
- chat:room:{id}      → Message broadcast
- user:online:{id}    → Presence tracking
- notification:{id}   → Push notification triggers
```

---

## 🚀 Deployment Architecture (AWS)

```
Region: us-east-1

VPC
├── Public Subnets (2 AZs)
│   ├── ALB
│   └── NAT Gateway
│
├── Private Subnets (2 AZs)  
│   ├── ECS Cluster (Fargate)
│   │   ├── api-gateway (2 tasks)
│   │   ├── auth-service (2 tasks)
│   │   ├── user-service (2 tasks)
│   │   ├── game-service (3 tasks)
│   │   ├── chat-service (3 tasks)
│   │   ├── wallet-service (2 tasks)
│   │   └── notification-service (2 tasks)
│   │
│   ├── RDS PostgreSQL (Multi-AZ)
│   └── ElastiCache Redis (Cluster Mode)
│
└── S3 Buckets
    ├── playraze-media (profile photos, game assets)
    └── playraze-backups (DB backups)
```