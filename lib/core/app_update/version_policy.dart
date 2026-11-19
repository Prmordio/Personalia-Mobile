/// Versão semântica simples (`3.4.2`, `3.4.2+42` — o build number é ignorado).
class AppVersion implements Comparable<AppVersion> {
  const AppVersion(this.major, this.minor, this.patch);

  final int major;
  final int minor;
  final int patch;

  /// `null` para texto vazio ou inválido (chave ausente no Remote Config = sem exigência).
  static AppVersion? tryParse(String? raw) {
    final text = raw?.trim().split('+').first ?? '';
    final match = RegExp(r'^(\d+)(?:\.(\d+))?(?:\.(\d+))?$').firstMatch(text);
    if (match == null) return null;
    int part(int i) => int.parse(match.group(i) ?? '0');
    return AppVersion(part(1), part(2), part(3));
  }

  @override
  int compareTo(AppVersion other) {
    if (major != other.major) return major.compareTo(other.major);
    if (minor != other.minor) return minor.compareTo(other.minor);
    return patch.compareTo(other.patch);
  }

  bool operator <(AppVersion other) => compareTo(other) < 0;

  @override
  bool operator ==(Object other) => other is AppVersion && compareTo(other) == 0;

  @override
  int get hashCode => Object.hash(major, minor, patch);

  @override
  String toString() => '$major.$minor.$patch';
}

enum UpdateRequirement { none, recommended, required }

/// Regra de atualização: abaixo da mínima bloqueia; abaixo da recomendada sugere.
/// Versão atual desconhecida nunca bloqueia (melhor deixar usar do que travar por engano).
UpdateRequirement evaluateUpdate({
  required AppVersion? current,
  AppVersion? minimum,
  AppVersion? recommended,
}) {
  if (current == null) return UpdateRequirement.none;
  if (minimum != null && current < minimum) return UpdateRequirement.required;
  if (recommended != null && current < recommended) return UpdateRequirement.recommended;
  return UpdateRequirement.none;
}
