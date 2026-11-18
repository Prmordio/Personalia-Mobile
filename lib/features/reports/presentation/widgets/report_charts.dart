import 'dart:math';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

/// Gráfico de barras simples (sem dependência externa). [labels] aparece sob cada barra.
/// Cada barra é anunciada ao leitor de tela como "rótulo: valor" ([valueLabel] formata o valor).
class SimpleBarChart extends StatelessWidget {
  const SimpleBarChart({
    super.key,
    required this.values,
    required this.labels,
    this.height = 140,
    this.highlightLast = false,
    this.valueLabel,
  });

  final List<num> values;
  final List<String> labels;
  final double height;
  final bool highlightLast;
  final String Function(num value)? valueLabel;

  @override
  Widget build(BuildContext context) {
    final maxValue = values.fold<num>(0, (m, v) => max(m, v));
    return SizedBox(
      height: height + 36,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < values.length; i++)
            Expanded(
              child: Semantics(
                label: '${labels[i]}: ${valueLabel?.call(values[i]) ?? values[i]}',
                excludeSemantics: true,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (values[i] > 0)
                        Text(_compact(values[i]), style: const TextStyle(fontSize: 10, color: Colors.grey)),
                      const SizedBox(height: 2),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 400),
                        height: maxValue == 0 ? 2 : max(2, height * values[i] / maxValue),
                        decoration: BoxDecoration(
                          color: highlightLast && i == values.length - 1
                              ? AppColors.orange
                              : AppColors.blue.withValues(alpha: 0.75),
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        labels[i],
                        style: const TextStyle(fontSize: 10, color: Colors.grey),
                        maxLines: 1,
                        overflow: TextOverflow.clip,
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  static String _compact(num v) => v >= 1000 ? '${(v / 1000).toStringAsFixed(1)}k' : v.round().toString();
}

/// Linha simples com pontos — evolução de peso ou carga.
/// [semanticLabel] descreve os pontos para o leitor de tela (o desenho em si é invisível a ele).
class SimpleLineChart extends StatelessWidget {
  const SimpleLineChart({
    super.key,
    required this.values,
    this.height = 120,
    this.color = AppColors.orange,
    this.semanticLabel,
  });

  final List<num> values;
  final double height;
  final Color color;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      image: true,
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: CustomPaint(painter: _LinePainter(values.map((v) => v.toDouble()).toList(), color)),
      ),
    );
  }
}

class _LinePainter extends CustomPainter {
  _LinePainter(this.values, this.color);
  final List<double> values;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    final minV = values.reduce(min);
    final maxV = values.reduce(max);
    final range = (maxV - minV).abs() < 0.001 ? 1.0 : maxV - minV;
    const pad = 8.0;

    Offset point(int i) {
      final x = values.length == 1 ? size.width / 2 : pad + (size.width - 2 * pad) * i / (values.length - 1);
      final y = pad + (size.height - 2 * pad) * (1 - (values[i] - minV) / range);
      return Offset(x, y);
    }

    final path = Path()..moveTo(point(0).dx, point(0).dy);
    for (var i = 1; i < values.length; i++) {
      path.lineTo(point(i).dx, point(i).dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
    final dot = Paint()..color = color;
    for (var i = 0; i < values.length; i++) {
      canvas.drawCircle(point(i), 3.5, dot);
    }
  }

  @override
  bool shouldRepaint(covariant _LinePainter old) => old.values != values || old.color != color;
}

/// Número grande + legenda (linha de estatísticas dos relatórios).
class StatTile extends StatelessWidget {
  const StatTile({super.key, required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: Colors.grey, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
