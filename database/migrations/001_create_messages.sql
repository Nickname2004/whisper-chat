CREATE TABLE IF NOT EXISTS messages (
  id UUID PRIMARY KEY,
  text TEXT NOT NULL CHECK (char_length(text) BETWEEN 1 AND 2000),
  sender_id TEXT NOT NULL CHECK (char_length(sender_id) BETWEEN 1 AND 100),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS messages_created_at_idx ON messages (created_at DESC);
