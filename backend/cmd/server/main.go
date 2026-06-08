package main

import (
	"log"
	"net/http"
	"os"

	"github.com/yourusername/3d-logic-gate-simulator/internal/simulation"
	"github.com/yourusername/3d-logic-gate-simulator/internal/websocket"
)

func main() {
	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	// Initialize the simulation engine
	sim := simulation.NewEngine()
	go sim.Run()

	// Initialize WebSocket hub
	hub := websocket.NewHub(sim)
	go hub.Run()

	// HTTP routes
	http.HandleFunc("/ws", func(w http.ResponseWriter, r *http.Request) {
		websocket.ServeWS(hub, w, r)
	})
	http.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
		w.Write([]byte(`{"status":"ok","service":"3d-logic-gate-simulator"}`))
	})

	// CORS middleware wrapper
	handler := corsMiddleware(http.DefaultServeMux)

	log.Printf("🚀 3D Logic Gate Simulator backend running on :%s", port)
	if err := http.ListenAndServe(":"+port, handler); err != nil {
		log.Fatalf("Server failed: %v", err)
	}
}

func corsMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Access-Control-Allow-Origin", "*")
		w.Header().Set("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
		w.Header().Set("Access-Control-Allow-Headers", "Content-Type, Authorization")
		if r.Method == http.MethodOptions {
			w.WriteHeader(http.StatusNoContent)
			return
		}
		next.ServeHTTP(w, r)
	})
}
