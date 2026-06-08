import 'package:flutter/material.dart';
import '../main.dart';
import '../models/simulation_state.dart';
import '../services/websocket_service.dart';

// ─────────────────────────────────────────────
//  Wire Panel (right sidebar)
// ─────────────────────────────────────────────

/// Right panel: list of wires and input toggles.
class WirePanel extends StatelessWidget {
  final SimulationState state;
  final WebSocketService service;

  const WirePanel({super.key, required this.state, required this.service});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _sectionHeader(context, 'ΕΙΣΟΔΟΙ', 'Inputs'),
          Expanded(flex: 1, child: _InputList(state: state, service: service)),
          const Divider(height: 1),
          _sectionHeader(context, 'ΣΥΝΔΕΣΕΙΣ', 'Wires'),
          Expanded(flex: 1, child: _WireList(state: state, service: service)),
          const Divider(height: 1),
          _GateOutputList(state: state),
        ],
      ),
    );
  }

  Widget _sectionHeader(BuildContext context, String greek, String english) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(greek, style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.textDim, letterSpacing: 2,
          )),
          Text(english, style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.accent, letterSpacing: 1,
          )),
        ],
      ),
    );
  }
}

// ── Input toggles ────────────────────────────
class _InputList extends StatelessWidget {
  final SimulationState state;
  final WebSocketService service;
  const _InputList({required this.state, required this.service});

  @override
  Widget build(BuildContext context) {
    if (state.gates.isEmpty) {
      return const _EmptyHint('Πρόσθεσε πύλη\nγια εισόδους');
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      itemCount: state.gates.length,
      itemBuilder: (_, gIdx) {
        final gate = state.gates[gIdx];
        final color = AppColors.gateColors[gate.type] ?? AppColors.accent;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${gate.type}  ${gate.id}',
                style: TextStyle(color: color, fontSize: 9, letterSpacing: 1),
              ),
              const SizedBox(height: 4),
              ...List.generate(gate.inputs.length, (iIdx) {
                return _InputToggle(
                  label: 'IN $iIdx',
                  value: gate.inputs[iIdx],
                  onChanged: (v) => service.setInput(gate.id, iIdx, v),
                );
              }),
            ],
          ),
        );
      },
    );
  }
}

class _InputToggle extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _InputToggle({
    required this.label, required this.value, required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final color = value ? AppColors.accentGreen : AppColors.textDim;
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: value
              ? AppColors.accentGreen.withOpacity(0.08)
              : AppColors.background,
          borderRadius: BorderRadius.circular(3),
          border: Border.all(color: color.withOpacity(0.5)),
        ),
        child: Row(
          children: [
            Icon(
              value ? Icons.toggle_on : Icons.toggle_off,
              color: color, size: 16,
            ),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(
              color: color, fontSize: 10, letterSpacing: 1,
            )),
            const Spacer(),
            Text(
              value ? '1  HIGH' : '0  LOW',
              style: TextStyle(color: color, fontSize: 9),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Wire list ────────────────────────────────
class _WireList extends StatelessWidget {
  final SimulationState state;
  final WebSocketService service;
  const _WireList({required this.state, required this.service});

  @override
  Widget build(BuildContext context) {
    if (state.wires.isEmpty) {
      return const _EmptyHint('Δεν υπάρχουν\nσυνδέσεις');
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      itemCount: state.wires.length,
      itemBuilder: (_, i) {
        final wire = state.wires[i];
        final color = wire.signal ? AppColors.accentGreen : AppColors.textDim;
        return Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: color.withOpacity(0.4)),
          ),
          child: Row(
            children: [
              Container(width: 6, height: 6,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${_shortId(wire.fromGateId)} → ${_shortId(wire.toGateId)}[${wire.toInputIdx}]',
                  style: TextStyle(color: color, fontSize: 9, letterSpacing: 0.8),
                ),
              ),
              GestureDetector(
                onTap: () => service.removeWire(wire.id),
                child: const Icon(Icons.close, size: 12, color: AppColors.textDim),
              ),
            ],
          ),
        );
      },
    );
  }

  String _shortId(String id) => id.length > 8 ? '…${id.substring(id.length - 5)}' : id;
}

// ── Gate output summary ──────────────────────
class _GateOutputList extends StatelessWidget {
  final SimulationState state;
  const _GateOutputList({required this.state});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ΕΞΟΔΟΙ / Outputs',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textDim, letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          ...state.gates.map((g) {
            final color = g.output ? AppColors.accentGreen : AppColors.accentRed;
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Container(width: 8, height: 8,
                    decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                  const SizedBox(width: 8),
                  Text(g.type,
                    style: TextStyle(color: AppColors.gateColors[g.type] ?? AppColors.onSurface,
                      fontSize: 10, letterSpacing: 1),
                  ),
                  const Spacer(),
                  Text(g.output ? '1' : '0',
                    style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Empty hint
// ─────────────────────────────────────────────
class _EmptyHint extends StatelessWidget {
  final String message;
  const _EmptyHint(this.message);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(message,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: AppColors.textDim, fontSize: 11, letterSpacing: 1, height: 1.6,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Status Bar (bottom)
// ─────────────────────────────────────────────
class StatusBar extends StatelessWidget {
  final SimulationState state;
  final WebSocketService service;

  const StatusBar({super.key, required this.state, required this.service});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _dot(AppColors.accentGreen),
          const SizedBox(width: 6),
          Text('ΣΥΝΔΕΔΕΜΕΝΟ', style: _style),
          const SizedBox(width: 24),
          Text('50 Hz  •  WebSocket', style: _style),
          const Spacer(),
          TextButton.icon(
            onPressed: service.reset,
            icon: const Icon(Icons.refresh, size: 14),
            label: const Text('RESET', style: TextStyle(fontSize: 10, letterSpacing: 2)),
            style: TextButton.styleFrom(foregroundColor: AppColors.accentRed),
          ),
        ],
      ),
    );
  }

  Widget _dot(Color color) => Container(
    width: 7, height: 7,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );

  TextStyle get _style => const TextStyle(
    color: AppColors.textDim, fontSize: 10, letterSpacing: 1.5,
  );
}
