// Package simulation implements the 3D logic-gate physics engine.
// It maintains gates, cubes, and wires in memory and evaluates the
// circuit every tick, broadcasting state deltas to connected clients.
package simulation

import (
	"fmt"
	"sync"
	"time"

	"github.com/yourusername/3d-logic-gate-simulator/internal/models"
)

const (
	tickRate        = 20 * time.Millisecond // 50 Hz simulation
	defaultGridSize = 10.0
)

// ─────────────────────────────────────────────
//  Engine
// ─────────────────────────────────────────────

// Engine is the central simulation state machine.
// All public methods are goroutine-safe.
type Engine struct {
	mu    sync.RWMutex
	gates map[string]*models.Gate
	cubes map[string]*models.Cube
	wires map[string]*models.Wire
	tick  int64

	// StateCh receives a fresh snapshot after every evaluation pass.
	StateCh chan models.SimulationState

	// CommandCh receives commands from WebSocket clients.
	CommandCh chan models.Message

	stopCh chan struct{}
	nextID int64
}

// NewEngine constructs a ready-to-use Engine and seeds a demo circuit.
func NewEngine() *Engine {
	e := &Engine{
		gates:     make(map[string]*models.Gate),
		cubes:     make(map[string]*models.Cube),
		wires:     make(map[string]*models.Wire),
		StateCh:   make(chan models.SimulationState, 8),
		CommandCh: make(chan models.Message, 64),
		stopCh:    make(chan struct{}),
	}
	e.seedDemo()
	return e
}

// ─────────────────────────────────────────────
//  Lifecycle
// ─────────────────────────────────────────────

// Run starts the simulation loop; call in a goroutine.
func (e *Engine) Run() {
	ticker := time.NewTicker(tickRate)
	defer ticker.Stop()

	for {
		select {
		case <-e.stopCh:
			return
		case msg := <-e.CommandCh:
			e.handleCommand(msg)
		case <-ticker.C:
			e.evaluate()
			snapshot := e.snapshot()
			select {
			case e.StateCh <- snapshot:
			default: // drop if channel full (slow client)
			}
		}
	}
}

// Stop signals the engine to halt.
func (e *Engine) Stop() { close(e.stopCh) }

// ─────────────────────────────────────────────
//  Command dispatch
// ─────────────────────────────────────────────

func (e *Engine) handleCommand(msg models.Message) {
	e.mu.Lock()
	defer e.mu.Unlock()

	switch msg.Type {
	case models.MsgAddGate:
		if p, ok := msg.Payload.(models.AddGatePayload); ok {
			e.addGate(p.GateType, p.Position)
		}
	case models.MsgRemoveGate:
		if p, ok := msg.Payload.(models.RemoveGatePayload); ok {
			e.removeGate(p.GateID)
		}
	case models.MsgSetInput:
		if p, ok := msg.Payload.(models.SetInputPayload); ok {
			e.setInput(p.GateID, p.InputIdx, p.Value)
		}
	case models.MsgAddWire:
		if p, ok := msg.Payload.(models.AddWirePayload); ok {
			e.addWire(p.FromGateID, p.ToGateID, p.ToInputIdx)
		}
	case models.MsgRemoveWire:
		if p, ok := msg.Payload.(models.RemoveWirePayload); ok {
			delete(e.wires, p.WireID)
		}
	case models.MsgAddCube:
		if p, ok := msg.Payload.(models.AddCubePayload); ok {
			e.addCube(p.Position, p.Color)
		}
	case models.MsgRemoveCube:
		if p, ok := msg.Payload.(models.RemoveCubePayload); ok {
			delete(e.cubes, p.CubeID)
		}
	case models.MsgReset:
		e.reset()
	}
}

// ─────────────────────────────────────────────
//  Circuit evaluation
// ─────────────────────────────────────────────

// evaluate propagates signals through all wires and recomputes gate outputs.
// Simple single-pass evaluation (no cycles supported in this version).
func (e *Engine) evaluate() {
	e.mu.Lock()
	defer e.mu.Unlock()

	e.tick++

	// Step 1: apply wire signals to gate inputs
	for _, wire := range e.wires {
		fromGate, ok := e.gates[wire.FromGateID]
		if !ok {
			continue
		}
		toGate, ok := e.gates[wire.ToGateID]
		if !ok {
			continue
		}
		wire.Signal = fromGate.Output
		if wire.ToInputIdx < len(toGate.Inputs) {
			toGate.Inputs[wire.ToInputIdx] = wire.Signal
		}
	}

	// Step 2: evaluate each gate
	for _, gate := range e.gates {
		prev := gate.Output
		gate.Output = gate.Evaluate()
		gate.Active = gate.Output != prev // highlight on state change
	}

	// Step 3: propagate lit state to cubes
	gateByPos := make(map[string]bool)
	for _, gate := range e.gates {
		key := posKey(gate.Position)
		gateByPos[key] = gate.Output
	}
	for _, cube := range e.cubes {
		if lit, found := gateByPos[posKey(cube.Position)]; found {
			cube.Lit = lit
		}
	}
}

// ─────────────────────────────────────────────
//  Mutation helpers (call with e.mu held)
// ─────────────────────────────────────────────

func (e *Engine) addGate(gt models.GateType, pos models.Vec3) *models.Gate {
	id := e.newID("gate")
	inputs := 2
	if gt == models.GateNOT {
		inputs = 1
	}
	g := &models.Gate{
		ID:       id,
		Type:     gt,
		Position: pos,
		Inputs:   make([]bool, inputs),
	}
	e.gates[id] = g
	// auto-place a cube at the same position
	e.addCube(pos, gateColor(gt))
	return g
}

func (e *Engine) removeGate(id string) {
	delete(e.gates, id)
	// prune dangling wires
	for wid, wire := range e.wires {
		if wire.FromGateID == id || wire.ToGateID == id {
			delete(e.wires, wid)
		}
	}
}

func (e *Engine) setInput(gateID string, idx int, value bool) {
	if g, ok := e.gates[gateID]; ok && idx < len(g.Inputs) {
		g.Inputs[idx] = value
	}
}

func (e *Engine) addWire(from, to string, inputIdx int) *models.Wire {
	id := e.newID("wire")
	w := &models.Wire{
		ID:         id,
		FromGateID: from,
		ToGateID:   to,
		ToInputIdx: inputIdx,
	}
	e.wires[id] = w
	return w
}

func (e *Engine) addCube(pos models.Vec3, color string) *models.Cube {
	id := e.newID("cube")
	c := &models.Cube{
		ID:       id,
		Position: pos,
		Scale:    models.Vec3{X: 1, Y: 1, Z: 1},
		Color:    color,
	}
	e.cubes[id] = c
	return c
}

func (e *Engine) reset() {
	e.gates = make(map[string]*models.Gate)
	e.cubes = make(map[string]*models.Cube)
	e.wires = make(map[string]*models.Wire)
	e.tick = 0
	e.seedDemo()
}

// ─────────────────────────────────────────────
//  Snapshot
// ─────────────────────────────────────────────

func (e *Engine) snapshot() models.SimulationState {
	e.mu.RLock()
	defer e.mu.RUnlock()

	gates := make([]models.Gate, 0, len(e.gates))
	for _, g := range e.gates {
		gates = append(gates, *g)
	}
	cubes := make([]models.Cube, 0, len(e.cubes))
	for _, c := range e.cubes {
		cubes = append(cubes, *c)
	}
	wires := make([]models.Wire, 0, len(e.wires))
	for _, w := range e.wires {
		wires = append(wires, *w)
	}
	return models.SimulationState{
		Gates: gates,
		Cubes: cubes,
		Wires: wires,
		Tick:  e.tick,
	}
}

// ─────────────────────────────────────────────
//  Demo circuit seed
// ─────────────────────────────────────────────

// seedDemo builds a simple AND→NOT chain so the simulator isn't empty on load.
func (e *Engine) seedDemo() {
	andGate := e.addGate(models.GateAND, models.Vec3{X: -2, Y: 0, Z: 0})
	notGate := e.addGate(models.GateNOT, models.Vec3{X: 2, Y: 0, Z: 0})
	e.addWire(andGate.ID, notGate.ID, 0)

	orGate := e.addGate(models.GateOR, models.Vec3{X: 0, Y: 0, Z: -3})
	e.addWire(orGate.ID, andGate.ID, 1)

	// Set some default inputs so the circuit is visually active
	andGate.Inputs[0] = true
	orGate.Inputs[0] = true
}

// ─────────────────────────────────────────────
//  Utilities
// ─────────────────────────────────────────────

func (e *Engine) newID(prefix string) string {
	e.nextID++
	return fmt.Sprintf("%s_%d", prefix, e.nextID)
}

func posKey(v models.Vec3) string {
	return fmt.Sprintf("%.1f:%.1f:%.1f", v.X, v.Y, v.Z)
}

func gateColor(gt models.GateType) string {
	switch gt {
	case models.GateAND:
		return "#00E5FF"
	case models.GateOR:
		return "#69FF47"
	case models.GateNOT:
		return "#FF4081"
	case models.GateNAND:
		return "#FF6D00"
	case models.GateNOR:
		return "#AA00FF"
	case models.GateXOR:
		return "#FFD740"
	default:
		return "#FFFFFF"
	}
}
