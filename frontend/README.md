# Whisper Chat client

Flutter web client for Whisper Chat. It connects to the Go API over WebSockets.

Run it against the local API with:

```powershell
flutter run -d edge --dart-define=WS_URL=ws://localhost:8080/ws
```

For Android Emulator, use `ws://10.0.2.2:8080/ws` instead.
