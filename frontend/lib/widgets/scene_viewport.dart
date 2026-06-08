import 'dart:math' as math;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../main.dart';
import '../models/simulation_state.dart';
import '../services/websocket_service.dart';

/// The 3D viewport that renders the simulation.
/// Uses a software perspective projection (isometric-ish) drawn via CustomPainter.
/// For a production app, swap this with a flutter_cube or three_dart scene.
class SceneViewport extends StatefulWidget {
  final SimulationState state;
  final WebSocketService service;

  const SceneViewport({
    super.key,
    required this.state,
    required this.service,
  });

  @override
  State<SceneViewport> createState() => _SceneViewportState();
}

class _SceneViewportState extends State<SceneViewport>
    with SingleTickerProviderStateMixin {
  // Camera controls
  double _azimuth = 0.6;      // horizontal angle (radians)
  double _elevation = 0.5;    // vertical angle
  double _zoom = 60.0;        // pixels per world unit
  Offset _panOffset = Offset.zero;

  // Interaction
  Offset? _lastPointer;
  String? _selectedGateId;

  late AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────
  //  Projection helpers
  // ─────────────────────────────────────────────

  /// Projects a world Vec3 to canvas Offset using a simple
  /// perspective + rotation transform.
  Offset _project(Vec3 world, Size canvasSize) {
    // Rotate around Y axis (azimuth)
    final ca = math.cos(_azimuth), sa = math.sin(_azimuth);
    final rx = world.x * ca - world.z * sa;
    final rz = world.x * sa + world.z * ca;

    // Rotate around X axis (elevation)
    final ce = math.cos(-_elevation), se = math.sin(-_elevation);
    final ry = world.y * ce - rz * se;
    final rz2 = world.y * se + rz * ce;

    // Simple perspective divide (d = camera distance)
    const d = 10.0;
    final scale = d / (d + rz2 + 8);

    final sx = rx * _zoom * scale;
    final sy = -ry * _zoom * scale;

    return Offset(
      canvasSize.width / 2 + sx + _panOffset.dx,
      canvasSize.height / 2 + sy + _panOffset.dy,
    );
  }

  // ─────────────────────────────────────────────
  //  Gestures
  // ─────────────────────────────────────────────

  void _onPointerDown(PointerDownEvent e) => _lastPointer = e.position;

  void _onPointerMove(PointerMoveEvent e) {
    if (_lastPointer == null) return;
    final delta = e.position - _lastPointer!;
    setState(() {
      if (e.buttons == kSecondaryMouseButton) {
        _panOffset += delta;
      } else {
        _azimuth += delta.dx * 0.005;
        _elevation = (_elevation + delta.dy * 0.005).clamp(-1.4, 1.4);
      }
      _lastPointer = e.position;
    });
  }

  void _onPointerUp(PointerUpEvent e) => _lastPointer = null;

  void _onScroll(PointerScrollEvent e) {
    setState(() {
      _zoom = (_zoom - e.scrollDelta.dy * 0.5).clamp(20.0, 200.0);
    });
  }

  // ─────────────────────────────────────────────
  //  Build
  // ─────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Grid background
        Positioned.fill(child: _GridBackground()),

        // 3D scene
        Listener(
          onPointerDown: _onPointerDown,
          onPointerMove: _onPointerMove,
          onPointerUp: _onPointerUp,
          onPointerSignal: (e) {
            if (e is PointerScrollEvent) _onScroll(e);
          },
          child: AnimatedBuilder(
            animation: _pulseCtrl,
            builder: (_, __) => CustomPaint(
              painter: _ScenePainter(
                state: widget.state,
                project: _project,
                pulse: _pulseCtrl.value,
                selectedGateId: _selectedGateId,
              ),
              child: const SizedBox.expand(),
            ),
          ),
        ),

        // Camera hint overlay
        Positioned(
          bottom: 16,
          left: 16,
          child: _CameraHint(),
        ),

        // Gate count badge
        Positioned(
          top: 12,
          right: 12,
          child: _StatsBadge(state: widget.state),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
//  CustomPainter – scene renderer
// ─────────────────────────────────────────────
class _ScenePainter extends CustomPainter {
  final SimulationState state;
  final Offset Function(Vec3, Size) project;
  final double pulse;
  final String? selectedGateId;

  const _ScenePainter({
    required this.state,
    required this.project,
    required this.pulse,
    this.selectedGateId,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawGrid(canvas, size);
    _drawWires(canvas, size);
    _drawCubes(canvas, size);
    _drawGateLabels(canvas, size);
  }

  void _drawGrid(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.surfaceLight.withOpacity(0.4)
      ..strokeWidth = 0.5;
    // Draw a flat grid on Y=0 plane, range –6..6
    for (int i = -6; i <= 6; i++) {
      final a = project(Vec3(i.toDouble(), 0, -6), size);
      final b = project(Vec3(i.toDouble(), 0, 6), size);
      canvas.drawLine(a, b, paint);
      final c = project(Vec3(-6, 0, i.toDouble()), size);
      final d = project(Vec3(6, 0, i.toDouble()), size);
      canvas.drawLine(c, d, paint);
    }
    // Axes
    final xPaint = Paint()..color = AppColors.accentRed.withOpacity(0.6) ..strokeWidth = 1.5;
    final zPaint = Paint()..color = AppColors.accentGreen.withOpacity(0.6) ..strokeWidth = 1.5;
    final yPaint = Paint()..color = AppColors.accent.withOpacity(0.6) ..strokeWidth = 1.5;
canvas.drawLine(project(const Vec3(0, 0, 0), size), project(const Vec3(3, 0, 0), size), xPaint);
canvas.drawLine(project(const Vec3(0, 0, 0), size), project(const Vec3(0, 0, 3), size), zPaint);
canvas.drawLine(project(const Vec3(0, 0, 0), size), project(const Vec3(0, 3, 0), size), yPaint);
  }

  void _drawWires(Canvas canvas, Size size) {
    // Build a gate-ID → position lookup
    final gatePos = <String, Vec3>{
      for (final g in state.gates) g.id: g.position,
    };

    for (final wire in state.wires) {
      final from = gatePos[wire.fromGateId];
      final to = gatePos[wire.toGateId];
      if (from == null || to == null) continue;

      final p1 = project(from, size);
      final p2 = project(to, size);

      final color = wire.signal ? AppColors.accentGreen : AppColors.textDim;
      final glow = wire.signal ? (0.3 + pulse * 0.4) : 0.0;

      if (wire.signal) {
        // Glow layer
        canvas.drawLine(
          p1, p2,
          Paint()
            ..color = AppColors.accentGreen.withOpacity(glow * 0.5)
            ..strokeWidth = 6
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
        );
      }
      canvas.drawLine(
        p1, p2,
        Paint()
          ..color = color
          ..strokeWidth = wire.signal ? 2.0 : 1.0,
      );
    }
  }

  void _drawCubes(Canvas canvas, Size size) {
    // Sort back-to-front for painter's algorithm (approx)
    final sorted = [...state.cubes];
    sorted.sort((a, b) =>
        (b.position.x + b.position.y + b.position.z)
            .compareTo(a.position.x + a.position.y + a.position.z));

    for (final cube in sorted) {
      _drawCube(canvas, size, cube);
    }
  }

  void _drawCube(Canvas canvas, Size size, Cube3D cube) {
    final pos = cube.position;
    final s = cube.scale.x * 0.5; // half-size

    // 8 vertices of the unit cube
    final verts = [
      Vec3(pos.x - s, pos.y - s, pos.z - s), // 0 LBB
      Vec3(pos.x + s, pos.y - s, pos.z - s), // 1 RBB
      Vec3(pos.x + s, pos.y + s, pos.z - s), // 2 RTB
      Vec3(pos.x - s, pos.y + s, pos.z - s), // 3 LTB
      Vec3(pos.x - s, pos.y - s, pos.z + s), // 4 LBF
      Vec3(pos.x + s, pos.y - s, pos.z + s), // 5 RBF
      Vec3(pos.x + s, pos.y + s, pos.z + s), // 6 RTF
      Vec3(pos.x - s, pos.y + s, pos.z + s), // 7 LTF
    ];

    final p = verts.map((v) => project(v, size)).toList();

    // Parse color
    final baseColor = _hexToColor(cube.color);
    final litBoost = cube.lit ? (0.3 + pulse * 0.4) : 0.0;

    // Face definitions [vertex indices, brightness multiplier]
    final faces = [
      ([3, 2, 6, 7], 1.0),  // top
      ([0, 1, 5, 4], 0.4),  // bottom
      ([4, 5, 6, 7], 0.85), // front
      ([0, 3, 7, 4], 0.65), // left
      ([1, 2, 6, 5], 0.65), // right
      ([0, 1, 2, 3], 0.5),  // back
    ];

    for (final (indices, brightness) in faces) {
      final path = Path()
        ..moveTo(p[indices[0]].dx, p[indices[0]].dy);
      for (int i = 1; i < indices.length; i++) {
        path.lineTo(p[indices[i]].dx, p[indices[i]].dy);
      }
      path.close();

      final faceColor = Color.lerp(
        baseColor.withOpacity(brightness * 0.85),
        AppColors.accentGreen,
        litBoost * 0.6,
      )!;

      canvas.drawPath(path, Paint()..color = faceColor);
      canvas.drawPath(
        path,
        Paint()
          ..color = AppColors.accent.withOpacity(0.25)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8,
      );
    }

    // Glow halo on lit cubes
    if (cube.lit) {
      final centre = project(pos, size);
      canvas.drawCircle(
        centre,
        20 + pulse * 8,
        Paint()
          ..color = baseColor.withOpacity(0.15 * pulse)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16),
      );
    }
  }

  void _drawGateLabels(Canvas canvas, Size size) {
    for (final gate in state.gates) {
      final centre = project(gate.position + Vec3(0, 0.7, 0), size);
      final color = AppColors.gateColors[gate.type] ?? AppColors.onSurface;

      final tp = TextPainter(
        text: TextSpan(
          text: gate.type,
          style: TextStyle(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      // Background pill
      final rect = Rect.fromCenter(
        center: centre,
        width: tp.width + 10,
        height: tp.height + 6,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(3)),
        Paint()..color = AppColors.surface.withOpacity(0.85),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(3)),
        Paint()
          ..color = color.withOpacity(0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8,
      );

      tp.paint(
        canvas,
        centre - Offset(tp.width / 2, tp.height / 2),
      );

      // Output signal indicator
      final indicator = gate.output ? AppColors.accentGreen : AppColors.accentRed;
      canvas.drawCircle(
        Offset(rect.right + 5, centre.dy),
        3,
        Paint()..color = indicator,
      );
    }
  }

  Color _hexToColor(String hex) {
    final h = hex.replaceFirst('#', '');
    return Color(int.parse('FF$h', radix: 16));
  }

  @override
  bool shouldRepaint(_ScenePainter old) =>
      old.state != state ||
      old.pulse != pulse ||
      old.selectedGateId != selectedGateId;
}

// ─────────────────────────────────────────────
//  Helper extension
// ─────────────────────────────────────────────
extension on Vec3 {
  static Vec3 get zero => const Vec3(0, 0, 0);
  Vec3 operator +(Vec3 o) => Vec3(x + o.x, y + o.y, z + o.z);
}

// ─────────────────────────────────────────────
//  Grid background widget
// ─────────────────────────────────────────────
class _GridBackground extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 1.2,
          colors: [AppColors.surfaceLight, AppColors.background],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Stats badge
// ─────────────────────────────────────────────
class _StatsBadge extends StatelessWidget {
  final SimulationState state;
  const _StatsBadge({required this.state});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.85),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.surfaceLight),
      ),
      child: Text(
        'GATES ${state.gates.length}  WIRES ${state.wires.length}',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textDim,
              letterSpacing: 1.5,
            ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Camera hint
// ─────────────────────────────────────────────
class _CameraHint extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.7),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.surfaceLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _hint('🖱  drag', 'rotate'),
          _hint('🖱  right-drag', 'pan'),
          _hint('⚙  scroll', 'zoom'),
        ],
      ),
    );
  }

  Widget _hint(String key, String action) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        children: [
          Text(key,   style: const TextStyle(color: AppColors.textDim,   fontSize: 10)),
          const SizedBox(width: 6),
          Text(action, style: const TextStyle(color: AppColors.onSurface, fontSize: 10)),
        ],
      ),
    );
  }
}
