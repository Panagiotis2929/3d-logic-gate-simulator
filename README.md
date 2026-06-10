# 3D Logic Gate Simulator

> Εκπαιδευτικό εργαλείο για μαθητές Λυκείου — Πληροφορική & Ψηφιακά Κυκλώματα

<img width="1919" height="1020" alt="Στιγμιότυπο οθόνης 2026-06-08 045612" src="https://github.com/user-attachments/assets/77f63bea-51c1-4db6-a315-87f851ac1b9b" />
<img width="1919" height="1020" alt="image" src="https://github.com/user-attachments/assets/1a2c4ab8-1c5f-420e-85f1-5987db205565" />

---

## Τι είναι αυτό

Ένα διαδραστικό 3D περιβάλλον όπου μαθητές μπορούν να:

- **Τοποθετούν** λογικές πύλες (AND, OR, NOT, NAND, NOR, XOR) σε 3D χώρο
- **Συνδέουν** πύλες με εικονικά καλώδια και να βλέπουν τα σήματα σε πραγματικό χρόνο
- **Εναλλάσσουν** εισόδους (0/1) και να παρατηρούν πώς αλλάζουν οι έξοδοι
- **Κατανοούν** πλήρη κυκλώματα μέσω οπτικής αναπαράστασης με χρωματιστούς 3D κύβους

*Δεν λειτουργούν τα κουμπιά του παιχνιδιού*

---

## Δομή Project

```
3d-logic-gate-simulator/
│
├── backend/                          
│   ├── cmd/
│   │   └── server/
│   │       └── main.go              
│   ├── internal/
│   │   ├── models/
│   │   │   └── models.go             
│   │   ├── simulation/
│   │   │   └── engine.go             
│   │   └── websocket/
│   │       └── hub.go                
│   ├── Dockerfile                   
│   ├── go.mod
│   └── go.sum
│
├── frontend/                     
│   ├── lib/
│   │   ├── main.dart                 
│   │   ├── models/
│   │   │   └── simulation_state.dart 
│   │   ├── services/
│   │   │   └── websocket_service.dart
│   │   ├── screens/
│   │   │   ├── splash_screen.dart    
│   │   │   └── simulator_screen.dart 
│   │   └── widgets/
│   │       ├── scene_viewport.dart  
│   │       ├── gate_palette.dart     
│   │       └── wire_panel.dart
│   ├── assets/
│   │   ├── images/
│   │   └── fonts/
│   └── pubspec.yaml
│
├── docs/                           
├── .github/
│   └── workflows/
│       └── ci.yml                  
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

### 1. Backend

```bash
cd backend

# Κατέβασε dependencies
go mod download

# Εκτέλεσε τον server (default port 8080)
go run ./cmd/server

# Ή με custom port:
PORT=9000 go run ./cmd/server
```

### 2. Frontend (Flutter)

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

## Επεκτάσεις για Μαθητές

Ιδέες για project επεκτάσεις:

- [ ] Αποθήκευση/φόρτωση κυκλωμάτων (JSON export)
- [ ] Half-adder και full-adder ως demo κυκλώματα
- [ ] Truth table generator από το τρέχον κύκλωμα
- [ ] Multiplayer (πολλοί μαθητές, μία σκηνή)
- [ ] Three.js / WebGL renderer για πλήρες 3D (Flutter Web)
- [ ] Clock signal generator (αυτόματη εναλλαγή 0/1)

---

## Author

**KYRANAS RALLIS-PANAGIOTIS**

GitHub: https://github.com/Panagiotis2929

