package main

import (
	"net/http"
	"net/http/httptest"
	"reflect"
	"testing"
)

func TestConfiguredOriginsNormalizesDuplicates(t *testing.T) {
	t.Setenv("ALLOWED_ORIGINS", " http://localhost:3000,https://whisper.example,http://localhost:3000, ")

	got := configuredOrigins()
	want := []string{"http://localhost:3000", "https://whisper.example"}
	if !reflect.DeepEqual(got, want) {
		t.Fatalf("configuredOrigins() = %v, want %v", got, want)
	}
}

func TestCorsOnlyAllowsConfiguredOrigins(t *testing.T) {
	next := http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
	})
	handler := cors(next, []string{"http://localhost:3000"})

	allowed := httptest.NewRecorder()
	allowedRequest := httptest.NewRequest(http.MethodOptions, "/healthz", nil)
	allowedRequest.Header.Set("Origin", "http://localhost:3000")
	handler.ServeHTTP(allowed, allowedRequest)
	if allowed.Code != http.StatusNoContent {
		t.Fatalf("allowed status = %d, want %d", allowed.Code, http.StatusNoContent)
	}
	if got := allowed.Header().Get("Access-Control-Allow-Origin"); got != "http://localhost:3000" {
		t.Fatalf("allowed origin header = %q", got)
	}

	rejected := httptest.NewRecorder()
	rejectedRequest := httptest.NewRequest(http.MethodOptions, "/healthz", nil)
	rejectedRequest.Header.Set("Origin", "https://untrusted.example")
	handler.ServeHTTP(rejected, rejectedRequest)
	if rejected.Code != http.StatusForbidden {
		t.Fatalf("rejected status = %d, want %d", rejected.Code, http.StatusForbidden)
	}
	if got := rejected.Header().Get("Access-Control-Allow-Origin"); got != "" {
		t.Fatalf("rejected origin header = %q, want empty", got)
	}
}
