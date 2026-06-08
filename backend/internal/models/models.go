package models

import "fmt"

// ─────────────────────────────────────────────
//  3D Vector
// ─────────────────────────────────────────────

// Vec3 represents a point or direction in 3D space.
type Vec3 struct {
	X float64 `json:"x"`
	Y float64 `json:"y"`
	Z float64 `json:"z"`
}

func (v Vec3) String() string {
	return fmt.Sprintf("(%.2f, %.2f, %.2f)", v.X, v.Y, v.Z)
}

// ─────────────────────────────────────────────
//  Logic Gate Types
// ─────────────────────────────────────────────

// GateType enumerates all supported logic gate operations.
type GateType string

const (
	GateAND  GateType = "AND"
	GateOR   GateType = "OR"
	GateNOT  GateType = "NOT"
	GateNAND GateType = "NAND"
	GateNOR  GateType = "NOR"
	GateXOR  GateType = "XOR"
)

// ─────────────────────────────────────────────
//  Logic Gate
// ─────────────────────────────────────────────

// Gate is a logic gate placed in 3D space.
type Gate struct {
	ID       string   `json:"id"`
	Type     GateType `json:"type"`
	Position Vec3     `json:"position"`
	Inputs   []bool   `json:"inputs"`
	Output   bool     `json:"output"`
	Active   bool     `json:"active"` // visual highlight state
}

// Evaluate computes the gate output from its current inputs.
func (g *Gate) Evaluate() bool {
	switch g.Type {
	case GateAND:
		if len(g.Inputs) == 0 {
			return false
		}
		for _, v := range g.Inputs {
			if !v {
				return false
			}
		}
		return true

	case GateOR:
		for _, v := range g.Inputs {
			if v {
				return true
			}
		}
		return false

	case GateNOT:
		if len(g.Inputs) > 0 {
			return !g.Inputs[0]
		}
		return true

	case GateNAND:
		andResult := true
		for _, v := range g.Inputs {
			if !v {
				andResult = false
				break
			}
		}
		return !andResult

	case GateNOR:
		for _, v := range g.Inputs {
			if v {
				return false
			}
		}
		return true

	case GateXOR:
		count := 0
		for _, v := range g.Inputs {
			if v {
				count++
			}
		}
		return count%2 == 1

	default:
		return false
	}
}

// ─────────────────────────────────────────────
//  3D Cube
// ─────────────────────────────────────────────

// Cube is a visual 3D cube that may carry a logic gate.
type Cube struct {
	ID       string   `json:"id"`
	Position Vec3     `json:"position"`
	Scale    Vec3     `json:"scale"`
	Color    string   `json:"color"`  // hex color, e.g. "#00E5FF"
	GateID   string   `json:"gateId"` // empty if no gate attached
	Lit      bool     `json:"lit"`    // glowing / powered state
}

// ─────────────────────────────────────────────
//  Wire connection between gates
// ─────────────────────────────────────────────

// Wire connects one gate's output to another gate's input slot.
type Wire struct {
	ID         string `json:"id"`
	FromGateID string `json:"fromGateId"`
	ToGateID   string `json:"toGateId"`
	ToInputIdx int    `json:"toInputIdx"`
	Signal     bool   `json:"signal"` // current carried value
}

// ─────────────────────────────────────────────
//  WebSocket message envelope
// ─────────────────────────────────────────────

// MessageType classifies inbound / outbound WebSocket messages.
type MessageType string

const (
	// Server → Client
	MsgStateUpdate MessageType = "STATE_UPDATE"
	MsgError       MessageType = "ERROR"

	// Client → Server
	MsgAddGate    MessageType = "ADD_GATE"
	MsgRemoveGate MessageType = "REMOVE_GATE"
	MsgSetInput   MessageType = "SET_INPUT"
	MsgAddWire    MessageType = "ADD_WIRE"
	MsgRemoveWire MessageType = "REMOVE_WIRE"
	MsgAddCube    MessageType = "ADD_CUBE"
	MsgRemoveCube MessageType = "REMOVE_CUBE"
	MsgReset      MessageType = "RESET"
)

// Message is the top-level WebSocket envelope.
type Message struct {
	Type    MessageType `json:"type"`
	Payload interface{} `json:"payload"`
}

// ─────────────────────────────────────────────
//  Simulation state snapshot
// ─────────────────────────────────────────────

// SimulationState is the full state broadcast to all clients every tick.
type SimulationState struct {
	Gates []Gate `json:"gates"`
	Cubes []Cube `json:"cubes"`
	Wires []Wire `json:"wires"`
	Tick  int64  `json:"tick"`
}

// ─────────────────────────────────────────────
//  Client action payloads
// ─────────────────────────────────────────────

type AddGatePayload struct {
	GateType GateType `json:"gateType"`
	Position Vec3     `json:"position"`
}

type RemoveGatePayload struct {
	GateID string `json:"gateId"`
}

type SetInputPayload struct {
	GateID   string `json:"gateId"`
	InputIdx int    `json:"inputIdx"`
	Value    bool   `json:"value"`
}

type AddWirePayload struct {
	FromGateID string `json:"fromGateId"`
	ToGateID   string `json:"toGateId"`
	ToInputIdx int    `json:"toInputIdx"`
}

type RemoveWirePayload struct {
	WireID string `json:"wireId"`
}

type AddCubePayload struct {
	Position Vec3   `json:"position"`
	Color    string `json:"color"`
}

type RemoveCubePayload struct {
	CubeID string `json:"cubeId"`
}
