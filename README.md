# Whisper Chat

A real-time chat starter built with a Flutter client, a Go WebSocket API, and PostgreSQL.

## Architecture

- `frontend/`: Flutter + Riverpod client, organized by Clean Architecture feature layers.
- `backend/`: Go HTTP/WebSocket service with a PostgreSQL repository.
- `database/`: versioned schema migration.
- `docker-compose.yml`: production-like local stack.

## Run locally

1. Copy `.env.example` to `.env` and set a strong database password.
2. Start the API and database: `docker compose up --build`.
3. In `frontend`, run `flutter pub get` then `flutter run --dart-define=WS_URL=ws://localhost:8080/ws`.

For an Android emulator, use `ws://10.0.2.2:8080/ws`. Flutter web and desktop can use `localhost`.

## API

- `GET /healthz` returns service health.
- `GET /ws?user_id=<id>` opens a WebSocket.
- Send `{ "type": "message", "text": "Hello" }`; all connected clients receive a `message` event.

The database migration is applied automatically by the API at startup. The project is ready to deploy as two containers (API and managed PostgreSQL, or both containers for a small self-hosted deployment). Set `DATABASE_URL`, `PORT`, and `ALLOWED_ORIGINS` in the deployment environment.
