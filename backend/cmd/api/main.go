package main

import (
	"context"
	"embed"
	"encoding/json"
	"errors"
	"log"
	"net/http"
	"os"
	"strings"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/google/uuid"
	"nhooyr.io/websocket"
)

//go:embed migrations/*.sql
var migrationFiles embed.FS

type Message struct {
	ID        string    `json:"id"`
	Text      string    `json:"text"`
	SenderID  string    `json:"senderId"`
	Timestamp time.Time `json:"timestamp"`
}

type inboundEvent struct { Type string `json:"type"`; Text string `json:"text"` }
type outboundEvent struct { Type string `json:"type"`; Message Message `json:"message"` }

type hub struct { clients map[*websocket.Conn]struct{}; register chan *websocket.Conn; unregister chan *websocket.Conn; broadcast chan outboundEvent }
func newHub() *hub { return &hub{clients: map[*websocket.Conn]struct{}{}, register: make(chan *websocket.Conn), unregister: make(chan *websocket.Conn), broadcast: make(chan outboundEvent, 32)} }
func (h *hub) run() { for { select {
	case c := <-h.register: h.clients[c] = struct{}{}
	case c := <-h.unregister: delete(h.clients, c)
	case event := <-h.broadcast:
		payload, _ := json.Marshal(event)
		for c := range h.clients { ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second); err := c.Write(ctx, websocket.MessageText, payload); cancel(); if err != nil { delete(h.clients, c); c.Close(websocket.StatusNormalClosure, "write failed") } }
	} } }

func main() {
	databaseURL := os.Getenv("DATABASE_URL")
	if databaseURL == "" { log.Fatal("DATABASE_URL is required") }
	pool, err := pgxpool.New(context.Background(), databaseURL); if err != nil { log.Fatal(err) }; defer pool.Close()
	if err = pool.Ping(context.Background()); err != nil { log.Fatal(err) }
	if err = migrate(context.Background(), pool); err != nil { log.Fatal(err) }
	h := newHub(); go h.run()
	mux := http.NewServeMux()
	mux.HandleFunc("GET /healthz", func(w http.ResponseWriter, r *http.Request) { w.Header().Set("Content-Type", "application/json"); json.NewEncoder(w).Encode(map[string]string{"status":"ok"}) })
	mux.HandleFunc("GET /ws", websocketHandler(pool, h))
	server := &http.Server{Addr: ":" + env("PORT", "8080"), Handler: cors(mux), ReadHeaderTimeout: 10 * time.Second}
	log.Printf("Whisper API listening on %s", server.Addr); log.Fatal(server.ListenAndServe())
}

func websocketHandler(pool *pgxpool.Pool, h *hub) http.HandlerFunc { return func(w http.ResponseWriter, r *http.Request) {
	senderID := strings.TrimSpace(r.URL.Query().Get("user_id")); if senderID == "" { http.Error(w, "user_id is required", http.StatusBadRequest); return }
	conn, err := websocket.Accept(w, r, &websocket.AcceptOptions{OriginPatterns: allowedOrigins()}); if err != nil { return }; defer conn.Close(websocket.StatusNormalClosure, "connection closed")
	h.register <- conn; defer func() { h.unregister <- conn }()
	rows, err := pool.Query(r.Context(), "SELECT id, text, sender_id, created_at FROM messages ORDER BY created_at ASC LIMIT 100")
	if err == nil { for rows.Next() { var message Message; rows.Scan(&message.ID, &message.Text, &message.SenderID, &message.Timestamp); payload, _ := json.Marshal(outboundEvent{Type: "message", Message: message}); ctx, cancel := context.WithTimeout(r.Context(), 5*time.Second); conn.Write(ctx, websocket.MessageText, payload); cancel() }; rows.Close() }
	for { _, data, err := conn.Read(r.Context()); if err != nil { return }; var event inboundEvent; if json.Unmarshal(data, &event) != nil || event.Type != "message" || strings.TrimSpace(event.Text) == "" || len([]rune(event.Text)) > 2000 { continue }
		message := Message{ID: uuid.NewString(), Text: strings.TrimSpace(event.Text), SenderID: senderID, Timestamp: time.Now().UTC()}
		if _, err := pool.Exec(r.Context(), "INSERT INTO messages (id, text, sender_id, created_at) VALUES ($1, $2, $3, $4)", message.ID, message.Text, message.SenderID, message.Timestamp); err != nil { continue }; h.broadcast <- outboundEvent{Type: "message", Message: message}
	}
} }
func migrate(ctx context.Context, pool *pgxpool.Pool) error { sql, err := migrationFiles.ReadFile("migrations/001_create_messages.sql"); if err != nil { return err }; _, err = pool.Exec(ctx, string(sql)); return err }
func env(key, fallback string) string { if value := os.Getenv(key); value != "" { return value }; return fallback }
func allowedOrigins() []string { raw := os.Getenv("ALLOWED_ORIGINS"); if raw == "" { return nil }; values := strings.Split(raw, ","); for i := range values { values[i] = strings.TrimSpace(strings.TrimPrefix(strings.TrimPrefix(values[i], "https://"), "http://")) }; return values }
func cors(next http.Handler) http.Handler { return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) { origin := r.Header.Get("Origin"); if origin != "" { w.Header().Set("Access-Control-Allow-Origin", origin); w.Header().Set("Vary", "Origin") }; if r.Method == http.MethodOptions { w.Header().Set("Access-Control-Allow-Methods", "GET, OPTIONS"); w.Header().Set("Access-Control-Allow-Headers", "Content-Type"); w.WriteHeader(http.StatusNoContent); return }; next.ServeHTTP(w, r) }) }
var _ = errors.New
