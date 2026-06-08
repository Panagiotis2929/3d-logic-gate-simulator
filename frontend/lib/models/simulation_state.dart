// Models that mirror the Go backend structs exactly.
// JSON field names must match the backend snake_case output.

// ─────────────────────────────────────────────
//  Vec3
// ─────────────────────────────────────────────
class Vec3 {
  final double x, y, z;
  const Vec3(this.x, this.y, this.z);

  factory Vec3.fromJson(Map<String, dynamic> j) =>
      Vec3((j['x'] as num).toDouble(), (j['y'] as num).toDouble(),
          (j['z'] as num).toDouble());

  Map<String, dynamic> toJson() => {'x': x, 'y': y, 'z': z};

  Vec3 operator +(Vec3 o) => Vec3(x + o.x, y + o.y, z + o.z);
  Vec3 operator -(Vec3 o) => Vec3(x - o.x, y - o.y, z - o.z);
  Vec3 operator *(double s) => Vec3(x * s, y * s, z * s);

  @override
  String toString() => '(${x.toStringAsFixed(1)}, '
      '${y.toStringAsFixed(1)}, ${z.toStringAsFixed(1)})';
}

// ─────────────────────────────────────────────
//  LogicGate
// ─────────────────────────────────────────────
class LogicGate {
  final String id;
  final String type;   // "AND" | "OR" | "NOT" | …
  final Vec3 position;
  final List<bool> inputs;
  final bool output;
  final bool active;

  const LogicGate({
    required this.id,
    required this.type,
    required this.position,
    required this.inputs,
    required this.output,
    required this.active,
  });

  factory LogicGate.fromJson(Map<String, dynamic> j) => LogicGate(
        id: j['id'] as String,
        type: j['type'] as String,
        position: Vec3.fromJson(j['position'] as Map<String, dynamic>),
        inputs: (j['inputs'] as List).map((e) => e as bool).toList(),
        output: j['output'] as bool,
        active: j['active'] as bool,
      );
}

// ─────────────────────────────────────────────
//  Cube3D
// ─────────────────────────────────────────────
class Cube3D {
  final String id;
  final Vec3 position;
  final Vec3 scale;
  final String color;   // hex string "#RRGGBB"
  final String gateId;
  final bool lit;

  const Cube3D({
    required this.id,
    required this.position,
    required this.scale,
    required this.color,
    required this.gateId,
    required this.lit,
  });

  factory Cube3D.fromJson(Map<String, dynamic> j) => Cube3D(
        id: j['id'] as String,
        position: Vec3.fromJson(j['position'] as Map<String, dynamic>),
        scale: Vec3.fromJson(j['scale'] as Map<String, dynamic>),
        color: j['color'] as String,
        gateId: (j['gateId'] as String?) ?? '',
        lit: j['lit'] as bool,
      );
}

// ─────────────────────────────────────────────
//  Wire
// ─────────────────────────────────────────────
class Wire {
  final String id;
  final String fromGateId;
  final String toGateId;
  final int toInputIdx;
  final bool signal;

  const Wire({
    required this.id,
    required this.fromGateId,
    required this.toGateId,
    required this.toInputIdx,
    required this.signal,
  });

  factory Wire.fromJson(Map<String, dynamic> j) => Wire(
        id: j['id'] as String,
        fromGateId: j['fromGateId'] as String,
        toGateId: j['toGateId'] as String,
        toInputIdx: j['toInputIdx'] as int,
        signal: j['signal'] as bool,
      );
}

// ─────────────────────────────────────────────
//  SimulationState
// ─────────────────────────────────────────────
class SimulationState {
  final List<LogicGate> gates;
  final List<Cube3D> cubes;
  final List<Wire> wires;
  final int tick;

  const SimulationState({
    required this.gates,
    required this.cubes,
    required this.wires,
    required this.tick,
  });

  factory SimulationState.empty() => const SimulationState(
        gates: [], cubes: [], wires: [], tick: 0,
      );

  factory SimulationState.fromJson(Map<String, dynamic> j) => SimulationState(
        gates: (j['gates'] as List)
            .map((e) => LogicGate.fromJson(e as Map<String, dynamic>))
            .toList(),
        cubes: (j['cubes'] as List)
            .map((e) => Cube3D.fromJson(e as Map<String, dynamic>))
            .toList(),
        wires: (j['wires'] as List)
            .map((e) => Wire.fromJson(e as Map<String, dynamic>))
            .toList(),
        tick: j['tick'] as int,
      );
}
