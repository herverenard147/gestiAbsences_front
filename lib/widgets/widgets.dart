import 'package:flutter/material.dart';
import '../constants.dart';

// ── Metric Card ─────────────────────────────────────────────
class MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final String? sub;
  final Color? valueColor;

  const MetricCard({super.key, required this.label, required this.value,
      this.sub, this.valueColor});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppConstants.background,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 11, color: AppConstants.secondary)),
      const SizedBox(height: 4),
      Text(value, style: TextStyle(
        fontSize: 22, fontWeight: FontWeight.w700,
        color: valueColor ?? AppConstants.primary,
      )),
      if (sub != null) ...[
        const SizedBox(height: 2),
        Text(sub!, style: const TextStyle(fontSize: 10, color: Color(0xFFAAA9A3))),
      ],
    ]),
  );
}

// ── Status Badge ─────────────────────────────────────────────
class StatusBadge extends StatelessWidget {
  final String label;
  final String type; // success | danger | warning | info

  const StatusBadge({super.key, required this.label, required this.type});

  Color get _bg => switch (type) {
    'success' => AppConstants.successBg,
    'danger'  => AppConstants.dangerBg,
    'warning' => AppConstants.warningBg,
    _         => AppConstants.infoBg,
  };

  Color get _fg => switch (type) {
    'success' => AppConstants.success,
    'danger'  => AppConstants.danger,
    'warning' => AppConstants.warning,
    _         => AppConstants.info,
  };

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(color: _bg, borderRadius: BorderRadius.circular(99)),
    child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: _fg)),
  );
}

// ── Presence Button ─────────────────────────────────────────
class PresenceButton extends StatelessWidget {
  final String statut;
  final VoidCallback onTap;

  const PresenceButton({super.key, required this.statut, required this.onTap});

  Color get _bg => switch (statut) {
    'present'  => AppConstants.successBg,
    'absent'   => AppConstants.dangerBg,
    'justifie' => AppConstants.warningBg,
    _          => Colors.grey.shade100,
  };

  Color get _fg => switch (statut) {
    'present'  => AppConstants.success,
    'absent'   => AppConstants.danger,
    'justifie' => AppConstants.warning,
    _          => AppConstants.secondary,
  };

  String get _label => switch (statut) {
    'present'  => 'P',
    'absent'   => 'A',
    'justifie' => 'J',
    _          => '?',
  };

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 32, height: 32,
      decoration: BoxDecoration(
        color: _bg,
        shape: BoxShape.circle,
        border: Border.all(color: _fg, width: 1),
      ),
      child: Center(child: Text(_label,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _fg))),
    ),
  );
}

// ── Section Header ───────────────────────────────────────────
class SectionHeader extends StatelessWidget {
  final String title;
  final Widget? action;

  const SectionHeader({super.key, required this.title, this.action});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(title, style: const TextStyle(
          fontSize: 13, fontWeight: FontWeight.w600, color: AppConstants.primary)),
      if (action != null) action!,
    ],
  );
}

// ── App Card ─────────────────────────────────────────────────
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;

  const AppCard({super.key, required this.child, this.padding});

  @override
  Widget build(BuildContext context) => Container(
    padding: padding ?? const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppConstants.surface,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: AppConstants.border),
    ),
    child: child,
  );
}

// ── Loading Overlay ──────────────────────────────────────────
class LoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Widget child;

  const LoadingOverlay({super.key, required this.isLoading, required this.child});

  @override
  Widget build(BuildContext context) => Stack(children: [
    child,
    if (isLoading)
      Container(
        color: Colors.white54,
        child: const Center(child: CircularProgressIndicator()),
      ),
  ]);
}

// ── Empty State ──────────────────────────────────────────────
class EmptyState extends StatelessWidget {
  final String message;
  final IconData icon;

  const EmptyState({super.key, required this.message, this.icon = Icons.inbox_outlined});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 48, color: AppConstants.border),
        const SizedBox(height: 12),
        Text(message, style: const TextStyle(fontSize: 13, color: AppConstants.secondary),
            textAlign: TextAlign.center),
      ]),
    ),
  );
}

// ── Avatar initiales ─────────────────────────────────────────
class InitialesAvatar extends StatelessWidget {
  final String initiales;
  final double size;

  const InitialesAvatar({super.key, required this.initiales, this.size = 40});

  @override
  Widget build(BuildContext context) => Container(
    width: size, height: size,
    decoration: const BoxDecoration(color: AppConstants.infoBg, shape: BoxShape.circle),
    child: Center(child: Text(initiales.toUpperCase(),
        style: TextStyle(fontSize: size * 0.35, fontWeight: FontWeight.w600,
            color: AppConstants.info))),
  );
}

// ── Confirmation dialog ──────────────────────────────────────
Future<bool?> showConfirmDialog(BuildContext context, String title, String message) =>
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        content: Text(message, style: const TextStyle(fontSize: 13)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Confirmer')),
        ],
      ),
    );

void showSnack(BuildContext context, String msg, {bool error = false}) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(msg),
    backgroundColor: error ? AppConstants.danger : AppConstants.success,
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
  ));
}
