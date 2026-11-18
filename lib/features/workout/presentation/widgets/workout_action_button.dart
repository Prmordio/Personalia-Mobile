import 'package:flutter/material.dart';

/// Botão compacto ícone + legenda usado nos cards de exercício e no cronômetro.
/// Sem [onPressed] fica cinza (desabilitado).
class WorkoutActionButton extends StatelessWidget {
  const WorkoutActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
    this.horizontalPadding = 12,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onPressed;
  final double horizontalPadding;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = onPressed != null ? color : Colors.grey;
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onPressed,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: effectiveColor, size: 26),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(color: effectiveColor, fontSize: 10, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}

/// Legenda pequena + valor (séries, reps, carga...).
class WorkoutStat extends StatelessWidget {
  const WorkoutStat(this.label, this.value, {super.key});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }
}
