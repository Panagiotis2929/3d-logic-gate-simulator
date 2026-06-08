// Package websocket handles all WebSocket client connections and
// routes messages between clients and the simulation engine.
package websocket

import (
	"encoding/json"
	"log"
	"net/http"
	"time"

	"github.com/gorilla/websocket"
	"github.com/yourusername/3d-logic-gate-simulator/internal/models"
	"github.com/yourusername/3d-logic-gate-simulator/internal/simulation"
)

// ─────────────────────────────────────────────
//  Upgrader
// ─────────────────────────────────────────────

var upgrader = websocket.Upgrader{
	ReadBufferSize:  1024,
	WriteBufferSize: 4096,
	// Allow all origins for development; tighten for production.
	CheckOrigin: func(r *http.Request) bool { return true },
}

// ─────────────────────────────────────────────
//  Hub – fan-out broadcaster
// ─────────────────────────────────────────────

// Hub maintains the set of active clients and broadcasts simulation states.
type Hub struct {
	clients    map[*Client]struct{}
	broadcast  chan models.SimulationState
	register   chan *Client
	unregister chan *Client
	engine     *simulation.Engine
}

// NewHub wires a Hub to the given simulation engine.
func NewHub(engine *simulation.Engine) *Hub {
	return &Hub{
		clients:    make(map[*Client]struct{}),
		broadcast:  engine.StateCh,
		register:   make(chan *Client, 4),
		unregister: make(chan *Client, 4),
		engine:     engine,
	}
}

// Run starts the hub event loop; call in a goroutine.
func (h *Hub) Run() {
	for {
		select {
		case client := <-h.register:
			h.clients[client] = struct{}{}
			log.Printf("🔌 Client connected  (total: %d)", len(h.clients))

		case client := <-h.unregister:
			if _, ok := h.clients[client]; ok {
				delete(h.clients, client)
				close(client.send)
				log.Printf("🔌 Client disconnected (total: %d)", len(h.clients))
			}

		case state := <-h.broadcast:
			msg := models.Message{Type: models.MsgStateUpdate, Payload: state}
			data, err := json.Marshal(msg)
			if err != nil {
				log.Printf("marshal error: %v", err)
				continue
			}
			for client := range h.clients {
				select {
				case client.send <- data:
				default:
					// Slow client – drop and disconnect
					close(client.send)
					delete(h.clients, client)
				}
			}
		}
	}
}

// ─────────────────────────────────────────────
//  Client
// ─────────────────────────────────────────────

const (
	writeWait      = 10 * time.Second
	pongWait       = 60 * time.Second
	pingPeriod     = (pongWait * 9) / 10
	maxMessageSize = 4096
)

// Client is a single WebSocket connection.
type Client struct {
	hub  *Hub
	conn *websocket.Conn
	send chan []byte
}

// ServeWS upgrades an HTTP connection to WebSocket and registers a Client.
func ServeWS(hub *Hub, w http.ResponseWriter, r *http.Request) {
	conn, err := upgrader.Upgrade(w, r, nil)
	if err != nil {
		log.Printf("upgrade error: %v", err)
		return
	}
	client := &Client{
		hub:  hub,
		conn: conn,
		send: make(chan []byte, 64),
	}
	hub.register <- client
	go client.writePump()
	go client.readPump()
}

// readPump reads messages from the WebSocket and forwards commands to the engine.
func (c *Client) readPump() {
	defer func() {
		c.hub.unregister <- c
		c.conn.Close()
	}()

	c.conn.SetReadLimit(maxMessageSize)
	c.conn.SetReadDeadline(time.Now().Add(pongWait))
	c.conn.SetPongHandler(func(string) error {
		c.conn.SetReadDeadline(time.Now().Add(pongWait))
		return nil
	})

	for {
		_, raw, err := c.conn.ReadMessage()
		if err != nil {
			if websocket.IsUnexpectedCloseError(err,
				websocket.CloseGoingAway, websocket.CloseAbnormalClosure) {
				log.Printf("ws read error: %v", err)
			}
			return
		}

		var envelope struct {
			Type    models.MessageType  `json:"type"`
			Payload json.RawMessage     `json:"payload"`
		}
		if err := json.Unmarshal(raw, &envelope); err != nil {
			log.Printf("bad message: %v", err)
			continue
		}

		cmd, err := decodePayload(envelope.Type, envelope.Payload)
		if err != nil {
			log.Printf("decode error: %v", err)
			continue
		}
		c.hub.engine.CommandCh <- cmd
	}
}

// writePump writes messages from the send channel to the WebSocket.
func (c *Client) writePump() {
	ticker := time.NewTicker(pingPeriod)
	defer func() {
		ticker.Stop()
		c.conn.Close()
	}()

	for {
		select {
		case message, ok := <-c.send:
			c.conn.SetWriteDeadline(time.Now().Add(writeWait))
			if !ok {
				c.conn.WriteMessage(websocket.CloseMessage, []byte{})
				return
			}
			w, err := c.conn.NextWriter(websocket.TextMessage)
			if err != nil {
				return
			}
			w.Write(message)
			// Flush any queued messages in the same write frame.
			n := len(c.send)
			for i := 0; i < n; i++ {
				w.Write([]byte{'\n'})
				w.Write(<-c.send)
			}
			if err := w.Close(); err != nil {
				return
			}

		case <-ticker.C:
			c.conn.SetWriteDeadline(time.Now().Add(writeWait))
			if err := c.conn.WriteMessage(websocket.PingMessage, nil); err != nil {
				return
			}
		}
	}
}

// ─────────────────────────────────────────────
//  Payload decoder
// ─────────────────────────────────────────────

func decodePayload(t models.MessageType, raw json.RawMessage) (models.Message, error) {
	var payload interface{}
	var err error

	switch t {
	case models.MsgAddGate:
		var p models.AddGatePayload
		err = json.Unmarshal(raw, &p)
		payload = p
	case models.MsgRemoveGate:
		var p models.RemoveGatePayload
		err = json.Unmarshal(raw, &p)
		payload = p
	case models.MsgSetInput:
		var p models.SetInputPayload
		err = json.Unmarshal(raw, &p)
		payload = p
	case models.MsgAddWire:
		var p models.AddWirePayload
		err = json.Unmarshal(raw, &p)
		payload = p
	case models.MsgRemoveWire:
		var p models.RemoveWirePayload
		err = json.Unmarshal(raw, &p)
		payload = p
	case models.MsgAddCube:
		var p models.AddCubePayload
		err = json.Unmarshal(raw, &p)
		payload = p
	case models.MsgRemoveCube:
		var p models.RemoveCubePayload
		err = json.Unmarshal(raw, &p)
		payload = p
	case models.MsgReset:
		payload = nil
	}

	if err != nil {
		return models.Message{}, err
	}
	return models.Message{Type: t, Payload: payload}, nil
}
