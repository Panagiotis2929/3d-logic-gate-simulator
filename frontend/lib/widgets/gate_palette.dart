import 'package:flutter/material.dart';
import '../main.dart';

/// Left sidebar: clickable cards for each gate type.
class GatePalette extends StatelessWidget {
  final void Function(String gateType) onAddGate;
  const GatePalette({super.key, required this.onAddGate});

  static const _gates = [
    _GateEntry('AND',  'A·B',       '0·0=0  1·1=1'),
    _GateEntry('OR',   'A+B',       '0+0=0  1+0=1'),
    _GateEntry('NOT',  'Ā',         '0→1  1→0'),
    _GateEntry('NAND', '¬(A·B)',    '0·0=1  1·1=0'),
    _GateEntry('NOR',  '¬(A+B)',    '0+0=1  1+0=0'),
    _GateEntry('XOR',  'A⊕B',       '0⊕0=0  1⊕1=0'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _header(context),
          const Divider(height: 1),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: _gates.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) => _GateCard(
                entry: _gates[i],
                onTap: () => onAddGate(_gates[i].type),
              ),
            ),
          ),
          const Divider(height: 1),
          _legend(context),
        ],
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ΠΥΛΕΣ', style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.textDim, letterSpacing: 3,
          )),
          const SizedBox(height: 2),
          Text('Logic Gates', style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppColors.accent,
          )),
        ],
      ),
    );
  }

  Widget _legend(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ΣΗΜΑΤΑ', style: Theme.of(context).textTheme.bodySmall?.copyWith(
            letterSpacing: 2, color: AppColors.textDim,
          )),
          const SizedBox(height: 6),
          _legendRow(AppColors.accentGreen, '1  HIGH'),
          _legendRow(AppColors.accentRed,   '0  LOW'),
        ],
      ),
    );
  }

  Widget _legendRow(Color color, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Container(width: 10, height: 10, decoration: BoxDecoration(
            color: color, shape: BoxShape.circle,
          )),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(
            color: AppColors.onSurface, fontSize: 10, letterSpacing: 1,
          )),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Gate entry model
// ─────────────────────────────────────────────
class _GateEntry {
  final String type;
  final String symbol;
  final String truth;
  const _GateEntry(this.type, this.symbol, this.truth);
}

// ─────────────────────────────────────────────
//  Gate card
// ─────────────────────────────────────────────
class _GateCard extends StatefulWidget {
  final _GateEntry entry;
  final VoidCallback onTap;
  const _GateCard({required this.entry, required this.onTap});

  @override
  State<_GateCard> createState() => _GateCardState();
}

class _GateCardState extends State<_GateCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final color = AppColors.gateColors[widget.entry.type] ?? AppColors.accent;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: _hovered
                ? color.withOpacity(0.12)
                : AppColors.background.withOpacity(0.5),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: _hovered ? color : AppColors.surfaceLight,
              width: _hovered ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              // Symbol circle
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withOpacity(0.15),
                  border: Border.all(color: color.withOpacity(0.6)),
                ),
                child: Center(
                  child: Text(
                    widget.entry.symbol,
                    style: TextStyle(
                      color: color,
                      fontSize: widget.entry.symbol.length > 2 ? 8 : 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.entry.type,
                      style: TextStyle(
                        color: color,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.entry.truth,
                      style: const TextStyle(
                        color: AppColors.textDim,
                        fontSize: 9,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.add_circle_outline, color: color.withOpacity(0.6), size: 16),
            ],
          ),
        ),
      ),
    );
  }
}
