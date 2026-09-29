import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

const _defaultEmojis = ['🏋️', '💪', '🔥', '🏃', '🧠', '⚡', '🥗', '🤸', '🚴', '🎯', '⏱️', '📈', '🦵', '🧘', '🥇'];

/// Loading divertido: alguns emojis lado a lado, cada um trocando por outro aleatório em
/// ritmos diferentes (com pulo + escala), para a espera da IA não parecer travada.
class EmojiLoader extends StatefulWidget {
  const EmojiLoader({
    super.key,
    this.emojis = _defaultEmojis,
    this.slots = 3,
    this.size = 34,
  });

  final List<String> emojis;
  final int slots;
  final double size;

  @override
  State<EmojiLoader> createState() => _EmojiLoaderState();
}

class _EmojiLoaderState extends State<EmojiLoader> with SingleTickerProviderStateMixin {
  final _random = Random();
  late final AnimationController _bounce;
  late final List<String> _current;
  final _timers = <Timer>[];

  @override
  void initState() {
    super.initState();
    _bounce = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat();
    _current = List.generate(widget.slots, (_) => _pick(const []));
    for (var slot = 0; slot < widget.slots; slot++) {
      // Intervalos diferentes por posição: as trocas não acontecem todas juntas.
      _timers.add(Timer.periodic(Duration(milliseconds: 650 + slot * 230), (_) => _swap(slot)));
    }
  }

  String _pick(List<String> avoid) {
    final options = widget.emojis.where((e) => !avoid.contains(e)).toList();
    return options[_random.nextInt(options.length)];
  }

  void _swap(int slot) {
    if (!mounted) return;
    setState(() => _current[slot] = _pick(_current));
  }

  @override
  void dispose() {
    for (final timer in _timers) {
      timer.cancel();
    }
    _bounce.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Carregando',
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var slot = 0; slot < widget.slots; slot++)
            AnimatedBuilder(
              animation: _bounce,
              builder: (context, child) {
                // Onda: cada emoji pula com um atraso em relação ao anterior.
                final phase = (_bounce.value + slot / widget.slots) % 1.0;
                final lift = sin(phase * pi).clamp(0.0, 1.0) * widget.size * 0.35;
                return Transform.translate(offset: Offset(0, -lift), child: child);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 350),
                  transitionBuilder: (child, animation) => ScaleTransition(
                    scale: CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
                    child: FadeTransition(opacity: animation, child: child),
                  ),
                  child: Text(
                    _current[slot],
                    key: ValueKey('$slot-${_current[slot]}'),
                    style: TextStyle(fontSize: widget.size),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
