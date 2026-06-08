# 3D Logic Gate Simulator

> Εκπαιδευτικό εργαλείο για μαθητές Λυκείου — Πληροφορική & Ψηφιακά Κυκλώματα

[![CI](https://github.com/yourusername/3d-logic-gate-simulator/actions/workflows/ci.yml/badge.svg)](https://github.com/yourusername/3d-logic-gate-simulator/actions)
![Go](https://img.shields.io/badge/Go-1.22-00ADD8?logo=go)
![Flutter](https://img.shields.io/badge/Flutter-3.22-02569B?logo=flutter)
![License](https://img.shields.io/badge/License-MIT-green)

---

## Τι είναι αυτό

Ένα διαδραστικό 3D περιβάλλον όπου μαθητές μπορούν να:

- **Τοποθετούν** λογικές πύλες (AND, OR, NOT, NAND, NOR, XOR) σε 3D χώρο
- **Συνδέουν** πύλες με εικονικά καλώδια και να βλέπουν τα σήματα σε πραγματικό χρόνο
- **Εναλλάσσουν** εισόδους (0/1) και να παρατηρούν πώς αλλάζουν οι έξοδοι
- **Κατανοούν** πλήρη κυκλώματα μέσω οπτικής αναπαράστασης με χρωματιστούς 3D κύβους

---

## Αρχιτεκτονική

```
┌─────────────────────────────────────────────────────────────┐
│  Flutter Frontend  (3D UI, WebSocket client)                │
│    • Perspective projection renderer (CustomPainter)        │
│    • Gate palette, wire panel, input toggles                │
└────────────────────┬────────────────────────────────────────┘
                     │  WebSocket  ws://localhost:8080/ws
                     │  JSON messages  50 Hz state broadcast
┌────────────────────▼────────────────────────────────────────┐
│  Go Backend  (simulation engine + WebSocket hub)            │
│    • 50 Hz simulation loop                                  │
│    • Logic evaluation: AND / OR / NOT / NAND / NOR / XOR   │
│    • Wire signal propagation                                │
│    • Fan-out broadcaster → all connected clients            │
└─────────────────────────────────────────────────────────────┘
```

---

## Δομή Project

```
3d-logic-gate-simulator/
│
├── backend/                          # Go backend
│   ├── cmd/
│   │   └── server/
│   │       └── main.go               ← HTTP server + CORS
│   ├── internal/
│   │   ├── models/
│   │   │   └── models.go             ← Vec3, Gate, Cube, Wire, Messages
│   │   ├── simulation/
│   │   │   └── engine.go             ← 50 Hz simulation loop & circuit eval
│   │   └── websocket/
│   │       └── hub.go                ← WebSocket hub + client read/write pumps
│   ├── Dockerfile                    ← Multi-stage Docker build (scratch image)
│   ├── go.mod
│   └── go.sum
│
├── frontend/                         # Flutter app
│   ├── lib/
│   │   ├── main.dart                 ← App entry, theme, colours
│   │   ├── models/
│   │   │   └── simulation_state.dart ← Dart mirrors of Go structs
│   │   ├── services/
│   │   │   └── websocket_service.dart← WebSocket client + Riverpod providers
│   │   ├── screens/
│   │   │   ├── splash_screen.dart    ← Animated intro screen
│   │   │   └── simulator_screen.dart ← Main 3-column layout
│   │   └── widgets/
│   │       ├── scene_viewport.dart   ← 3D renderer (perspective projection)
│   │       ├── gate_palette.dart     ← Left sidebar, gate cards
│   │       └── wire_panel.dart       ← Right sidebar + bottom status bar
│   ├── assets/
│   │   ├── images/
│   │   └── fonts/
│   └── pubspec.yaml
│
├── docs/                             # Επιπλέον τεκμηρίωση
├── .github/
│   └── workflows/
│       └── ci.yml                    ← GitHub Actions CI (Go + Flutter + Docker)
├── docker-compose.yml
└── README.md
```

---

## Προαπαιτούμενα

| Εργαλείο | Έκδοση | Σύνδεσμος |
|----------|--------|-----------|
| Go | ≥ 1.22 | https://go.dev/dl/ |
| Flutter | ≥ 3.22 | https://docs.flutter.dev/get-started/install |
| Docker (προαιρετικό) | ≥ 24 | https://docs.docker.com/engine/install/ |
| Git | ≥ 2.40 | https://git-scm.com/ |

---

## Εγκατάσταση & Εκτέλεση

### 1. Clone το repository

```bash
git clone https://github.com/yourusername/3d-logic-gate-simulator.git
cd 3d-logic-gate-simulator
```

### 2. Backend (Go)

```bash
cd backend

# Κατέβασε dependencies
go mod download

# Εκτέλεσε τον server (default port 8080)
go run ./cmd/server

# Ή με custom port:
PORT=9000 go run ./cmd/server
```

Επαλήθευση:
```bash
curl http://localhost:8080/health
# → {"status":"ok","service":"3d-logic-gate-simulator"}
```

### 3. Frontend (Flutter)

Σε νέο terminal:

```bash
cd frontend

# Κατέβασε dependencies
flutter pub get

# Εκτέλεσε για web (προτεινόμενο για το 3D)
flutter run -d chrome --web-renderer html

# Ή για desktop (macOS / Linux / Windows)
flutter run -d macos   # ή linux / windows

# Ή για Android
flutter run -d android
```

> **Σημείωση για Android emulator:** Άλλαξε το URL στο `websocket_service.dart`:
> ```dart
> return 'ws://10.0.2.2:8080/ws'; // Android emulator → host machine
> ```

### 4. Docker (εναλλακτικά για backend)

```bash
# Μόνο backend
docker-compose up --build

# Ή χειροκίνητα
docker build -t logic-gate-backend backend/
docker run -p 8080:8080 logic-gate-backend
```

---

## Χρήση

| Ενέργεια | Πώς |
|----------|-----|
| Προσθήκη πύλης | Κλικ στην κάρτα πύλης στα αριστερά |
| Περιστροφή σκηνής | Drag αριστερά κουμπί ποντικιού |
| Μετακίνηση (pan) | Drag δεξί κουμπί ποντικιού |
| Zoom | Scroll |
| Toggle εισόδου | Κλικ σε κουμπί IN 0 / IN 1 στα δεξιά |
| Διαγραφή σύνδεσης | Κλικ ✕ δίπλα στο wire |
| Reset | Κουμπί RESET κάτω δεξιά |

---

## WebSocket API

Όλα τα μηνύματα είναι JSON με μορφή `{"type": "...", "payload": {...}}`.

### Client → Server

| type | payload | Περιγραφή |
|------|---------|-----------|
| `ADD_GATE` | `{gateType, position:{x,y,z}}` | Προσθήκη πύλης |
| `REMOVE_GATE` | `{gateId}` | Διαγραφή πύλης |
| `SET_INPUT` | `{gateId, inputIdx, value}` | Αλλαγή εισόδου |
| `ADD_WIRE` | `{fromGateId, toGateId, toInputIdx}` | Σύνδεση πυλών |
| `REMOVE_WIRE` | `{wireId}` | Διαγραφή καλωδίου |
| `ADD_CUBE` | `{position:{x,y,z}, color:"#RRGGBB"}` | Προσθήκη κύβου |
| `RESET` | `null` | Επαναφορά |

### Server → Client (50 Hz)

```json
{
  "type": "STATE_UPDATE",
  "payload": {
    "gates": [{"id":"gate_1","type":"AND","position":{"x":-2,"y":0,"z":0},"inputs":[true,false],"output":false,"active":false}],
    "cubes": [{"id":"cube_1","position":{"x":-2,"y":0,"z":0},"scale":{"x":1,"y":1,"z":1},"color":"#00E5FF","gateId":"","lit":false}],
    "wires": [{"id":"wire_1","fromGateId":"gate_1","toGateId":"gate_2","toInputIdx":0,"signal":false}],
    "tick": 1024
  }
}
```

---

## Ανέβασμα στο GitHub

### Α. Δημιουργία repository

1. Πήγαινε στο [github.com/new](https://github.com/new)
2. Όνομα: `3d-logic-gate-simulator`
3. Κράτα το **Public** (για εκπαιδευτικούς σκοπούς)
4. **ΜΗΝ** αρχικοποιήσεις με README — το έχουμε ήδη

### Β. Push κώδικα

```bash
# Μέσα στον φάκελο του project
git init
git add .
git commit -m "feat: initial 3D Logic Gate Simulator

- Go backend with 50 Hz WebSocket simulation loop
- AND/OR/NOT/NAND/NOR/XOR gate evaluation
- Flutter 3D renderer with perspective projection
- Riverpod state management
- Docker + GitHub Actions CI"

# Αντικατέστησε το URL με το δικό σου
git remote add origin https://github.com/yourusername/3d-logic-gate-simulator.git
git branch -M main
git push -u origin main
```

### Γ. Ενεργοποίηση GitHub Actions

Το CI τρέχει αυτόματα μετά το πρώτο push. Δες την πρόοδο στο:
```
https://github.com/yourusername/3d-logic-gate-simulator/actions
```

### Δ. Ενημέρωση go.mod (σημαντικό!)

Άλλαξε το module path στο `backend/go.mod` και σε όλα τα import:
```
module github.com/yourusername/3d-logic-gate-simulator
         ^^^^^^^^^^^^ αντικατέστησε με το GitHub username σου
```

Μετά:
```bash
cd backend
go mod tidy
```

---

## Τεχνικές Λεπτομέρειες

### Simulation Engine (Go)

- **50 Hz loop** με `time.Ticker` (20ms tick)
- **Single-pass propagation**: Wires → Gate inputs → Gate evaluate
- **Thread-safe** με `sync.RWMutex`
- **Fan-out hub** με goroutine-per-client (read/write pump pattern)
- **Ping/pong keepalive** κάθε 54 δευτερόλεπτα

### 3D Renderer (Flutter)

- **Perspective projection** με custom matrix (azimuth + elevation + zoom)
- **Painter's algorithm** για σωστή σειρά ζωγραφικής κύβων (back-to-front)
- **Glow effects** με `MaskFilter.blur` για lit κύβους
- **60 Hz** animation loop με `AnimationController` + `AnimatedBuilder`

---

## Επεκτάσεις για Μαθητές

Ιδέες για project επεκτάσεις:

- [ ] Αποθήκευση/φόρτωση κυκλωμάτων (JSON export)
- [ ] Half-adder και full-adder ως demo κυκλώματα
- [ ] Truth table generator από το τρέχον κύκλωμα
- [ ] Multiplayer (πολλοί μαθητές, μία σκηνή)
- [ ] Three.js / WebGL renderer για πλήρες 3D (Flutter Web)
- [ ] Clock signal generator (αυτόματη εναλλαγή 0/1)

---

## Άδεια

MIT License — ελεύθερη χρήση για εκπαιδευτικούς σκοπούς.

---

*Φτιαγμένο με ❤️ για μαθητές Λυκείου που αγαπάνε την Πληροφορική*
