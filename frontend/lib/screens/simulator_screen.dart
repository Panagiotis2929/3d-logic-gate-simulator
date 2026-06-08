import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../main.dart';
import '../models/simulation_state.dart';
import '../services/websocket_service.dart';
import '../widgets/gate_palette.dart';
import '../widgets/scene_viewport.dart';
//import '../widgets/status_bar.dart';
import '../widgets/wire_panel.dart';

/// The primary simulator screen.
/// Layout: [GatePalette | SceneViewport | WirePanel]
class SimulatorScreen extends ConsumerWidget {
  const SimulatorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final simState = ref.watch(simulationStateProvider);
    final wsService = ref.read(websocketServiceProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _AppBar(tick: simState.tick),
      body: Row(
        children: [
          // ── Left panel: gate palette ───────────────────────
          SizedBox(
            width: 200,
            child: GatePalette(
              onAddGate: (type) => wsService.addGate(
                type,
                _randomPos(),
                0,
                _randomPos(),
              ),
            ),
          ),

          const VerticalDivider(width: 1),

          // ── Centre: 3D viewport ────────────────────────────
          Expanded(
            child: SceneViewport(state: simState, service: wsService),
          ),

          const VerticalDivider(width: 1),

          // ── Right panel: wires & inputs ────────────────────
          SizedBox(
            width: 240,
            child: WirePanel(state: simState, service: wsService),
          ),
        ],
      ),
      bottomNavigationBar: StatusBar(state: simState, service: wsService),
    );
  }

  double _randomPos() => ((DateTime.now().millisecondsSinceEpoch % 8) - 4).toDouble();
}

// ─────────────────────────────────────────────
//  Custom AppBar
// ─────────────────────────────────────────────
class _AppBar extends StatelessWidget implements PreferredSizeWidget {
  final int tick;
  const _AppBar({required this.tick});

  @override
  Size get preferredSize => const Size.fromHeight(48);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          // Logo / title
          Row(
            children: [
              Icon(Icons.hub_rounded, color: AppColors.accent, size: 22),
              const SizedBox(width: 8),
              Text(
                '3D LOGIC GATE SIMULATOR',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.accent,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 3,
                    ),
              ),
            ],
          ),

          const Spacer(),

          // Tick counter
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.surfaceLight),
              borderRadius: BorderRadius.circular(3),
            ),
            child: Text(
              'TICK  ${tick.toString().padLeft(8, '0')}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.accentGreen,
                    letterSpacing: 2,
                  ),
            ),
          ),
          const SizedBox(width: 12),

          // Educational tag
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(3),
              border: Border.all(color: AppColors.accent.withOpacity(0.4)),
            ),
            child: Text(
              'ΛΥΚΕΙΟ  •  ΠΛΗΡΟΦΟΡΙΚΗ',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.accent,
                    letterSpacing: 1.5,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
