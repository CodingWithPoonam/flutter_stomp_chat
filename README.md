# Real-Time WebSocket Chat Application (Flutter + Spring Boot + STOMP + PostgreSQL)

A portfolio-quality, production-grade real-time messaging application demonstrating **Clean Architecture**, **BLoC state management** in Flutter, **Spring Boot 3 + Spring Security + JWT** backend, **STOMP over WebSocket** protocol, and **PostgreSQL** relational database design.

---

## Architecture Overview

```
                      ┌────────────────────────────────────────┐
                      │          Flutter Mobile App            │
                      │  (Presentation · BLoC · Domain · Data) │
                      └───────┬────────────────────────┬───────┘
                              │                        │
                 HTTPS REST   │                        │  WSS STOMP
             Auth & History   │                        │  Real-time Events
                              ▼                        ▼
                      ┌────────────────────────────────────────┐
                      │          Spring Boot Backend           │
                      │  (Security · JWT · STOMP MessageBroker)│
                      └───────────────────┬────────────────────┘
                                          │
                                   JPA / Hibernate
                                          ▼
                      ┌────────────────────────────────────────┐
                      │          PostgreSQL Database           │
                      │  (Users · Conversations · Members ·    │
                      │   Messages with Composite Indexes)     │
                      └────────────────────────────────────────┘
```

---

## What We Implemented & The Purpose of Each Component

### 1. Backend Architecture (Spring Boot 3 + Java 17)

| Package / Component | Implementation | Purpose & Use |
| :--- | :--- | :--- |
| `domain/User.java` | JPA entity with UUID, username, email, BCrypt passwordHash, status | Represents registered accounts and persists profile/online state. |
| `domain/Conversation.java` | JPA entity supporting `DIRECT` (1-on-1) and `GROUP` conversations | Tracks conversation type, creator, and latest message reference for list previews. |
| `domain/ConversationMember.java` | JPA entity with unique constraint on `(conversation_id, user_id)` | Enforces membership. Users can only access chats they belong to. |
| `domain/Message.java` | JPA entity with composite index `(conversation_id, sent_at DESC)` | Persists chat history with fast sub-millisecond paginated queries. |
| `config/JwtService.java` | JJWT 0.12 token issuer, signer, and parser | Generates stateless JWT tokens for both HTTP REST and WebSocket STOMP connections. |
| `config/JwtAuthenticationFilter.java` | `OncePerRequestFilter` inspecting `Authorization: Bearer <jwt>` | Authenticates all incoming HTTP REST requests and populates `SecurityContext`. |
| `config/WebSocketAuthChannelInterceptor.java` | Spring Messaging `ChannelInterceptor` | Authenticates STOMP `CONNECT` frame via JWT and authorizes `SUBSCRIBE` requests to ensure membership. |
| `config/WebSocketConfig.java` | `WebSocketMessageBrokerConfigurer` with `/ws` endpoint & `/topic`, `/queue` brokers | Configures the STOMP message broker routing messages between mobile clients. |
| `service/AuthService.java` | Registration, credential validation, BCrypt hashing, JWT generation | Handles user authentication lifecycle and profile queries. |
| `service/ChatService.java` | Direct & group chat creation, membership checks, message persistence | Core business logic enforcing authorization rules and transaction boundaries. |
| `controller/ChatWebSocketController.java` | `@MessageMapping("/chat.send")` & `@MessageMapping("/chat.typing")` | Receives incoming STOMP messages and broadcasts them to conversation topics. |

---

### 2. Mobile Architecture (Flutter + BLoC + Clean Architecture)

```
lib/
├── core/
│   ├── constants/       # REST and STOMP topic destinations
│   ├── network/         # Dio client + AuthInterceptor injecting JWT
│   ├── storage/         # FlutterSecureStorage for encrypted JWT persistence
│   ├── websocket/       # StompClientService managing persistent WSS connection
│   ├── theme/           # Dark/Light modern theme with Google Fonts (Outfit)
│   └── di/              # GetIt dependency injection registry
└── features/
    ├── auth/            # Presentation (BLoC/UI) -> Domain (UseCases) -> Data (Dio/Storage)
    ├── conversations/   # Direct & Group chat creation, live list sorting
    └── chat/            # Real-time messaging, reverse scroll, ephemeral typing
```

| Layer | Component | Purpose & Use |
| :--- | :--- | :--- |
| **Core Network** | `Dio` + `AuthInterceptor` | Injects `Authorization: Bearer <token>` on all REST calls; handles 401 unauthenticated signals. |
| **Core STOMP** | `StompClientService` | Encapsulates `stomp_dart_client`, manages heartbeat, auto-reconnect, and dynamic topic subscriptions. |
| **Auth Feature** | `AuthBloc`, `LoginScreen`, `RegisterScreen` | User session state management; automatically triggers STOMP socket activation upon authentication. |
| **Conversations** | `ConversationBloc`, `ConversationListScreen` | Fetches active chats and dynamically moves conversations to the top when new messages arrive. |
| **Chat Feature** | `ChatBloc`, `ChatScreen` | Merges persistent history with live STOMP messages and handles ephemeral typing indicators. |
| **Chat UI** | `MessageBubble`, `ChatInputBar`, `TypingIndicatorWidget` | Telegram/iMessage-inspired bubbles, debounced typing event dispatch, and animated pulsing dots. |

---

## STOMP Protocol & Topic Design

Rather than transmitting raw unformatted WebSocket byte frames, **STOMP** (Simple Text Oriented Messaging Protocol) introduces structured publish-subscribe routing:

1. **Authentication Handshake**:
   - Client sends STOMP frame:
     ```stomp
     CONNECT
     Authorization: Bearer <jwt_token>
     accept-version:1.2,1.1,1.0
     ```
   - Server validates JWT in `WebSocketAuthChannelInterceptor` and sets `Principal` in the session.

2. **Topic Subscription**:
   - Mobile client subscribes to conversation events:
     ```stomp
     SUBSCRIBE
     id:sub-1
     destination:/topic/conversation.<conversationId>
     ```
   - Server verifies conversation membership before granting subscription.

3. **Sending a Message**:
   - Mobile client sends STOMP frame:
     ```stomp
     SEND
     destination:/app/chat.send
     content-type:application/json

     {"conversationId":"...","content":"Hello World!"}
     ```
   - Server receives message, persists to database, and broadcasts to `/topic/conversation.<id>`.

4. **Ephemeral Typing Indicators**:
   - Dispatched to `/app/chat.typing` with `{"conversationId":"...","typing":true}`.
   - Broadcasted in-memory to `/topic/conversation.<id>.typing`.
   - **Zero Database Load**: Typing events are transient and never written to disk.

---

## How to Run

### Step 1: Run the Spring Boot Backend

The backend includes a **zero-setup `dev` profile** (H2 in PostgreSQL compatibility mode) for instant local development, plus a full **`prod` profile** with PostgreSQL.

```bash
cd backend

# Option A: Run instantly in dev mode (zero setup required)
.\mvnw.cmd spring-boot:run

# Option B: Run with PostgreSQL via Docker Compose
docker compose up -d
.\mvnw.cmd spring-boot:run -Dspring-boot.run.profiles=prod
```

Backend endpoints:
- REST API: `http://localhost:8080/api/v1`
- WebSocket STOMP: `ws://localhost:8080/ws`
- H2 Web Console: `http://localhost:8080/h2-console` (JDBC URL: `jdbc:h2:mem:chatdb`)

### Step 2: Run Backend Tests

```bash
cd backend
.\mvnw.cmd test
```
*Results: 5/5 Integration Tests Passed (Auth flow, Direct chats, Group chats, Messaging history, Security membership enforcement).*

### Step 3: Run the Flutter Mobile App

```bash
cd mobile

# Fetch packages
flutter pub get

# Run unit and widget tests
flutter test

# Launch on Android emulator, iOS simulator, or Chrome/Windows desktop
flutter run
```

---

## Pre-Seeded Quick Demo Logins

The mobile login screen includes **Quick Fill Chips** to test real-time conversations across two devices/windows instantly:

- **Alice Smith**: username `alice`, password `password123`
- **Bob Jones**: username `bob`, password `password123`
- **Charlie Brown**: username `charlie`, password `password123`
