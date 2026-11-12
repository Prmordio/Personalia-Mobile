#!/usr/bin/env python3
"""Resumo dos testes integrados a partir dos logs do `flutter test` gravados pelo run.sh.

Uso: report.py <pasta do relatório>   (lê <arquivo>.log e <arquivo>.status; grava resumo.md)

O run.sh grava um log só (e2e.log, do integration_test/all_test.dart), em que cada teste vem
prefixado pelo grupo — o nome do arquivo de origem —, que vira a coluna "Arquivo" do resumo.

Cada teste aparece nas linhas de progresso do reporter ("01:16 +1 -2: nome") e, quando falha,
uma vez com " [E]" no fim. O resumo lista cada teste com ✅/❌ e, nos que falharam, a primeira
mensagem de erro (o "Não apareceu…" do AppDriver já diz em que tela parou).
"""
import re
import sys
from pathlib import Path

PROGRESS = re.compile(r"^\d+:\d+ \+\d+(?: ~\d+)?(?: -\d+)?: (.+)$")
NOT_A_TEST = ("loading ", "(setUpAll)", "(tearDownAll)", "Some tests failed", "All tests passed")


def parse(log: str):
    order, failed, errors = [], set(), {}
    current_error = None
    for line in log.splitlines():
        match = PROGRESS.match(line)
        if match:
            name = match.group(1).strip()
            if name.startswith(NOT_A_TEST):
                continue
            is_error = name.endswith("[E]")
            name = name.removesuffix("[E]").strip()
            if name not in order:
                order.append(name)
            if is_error:
                failed.add(name)
                if current_error and name not in errors:
                    errors[name] = current_error
                current_error = None
        elif "EXCEPTION CAUGHT" in line:
            current_error = ""
        elif current_error == "" and line.strip() and not line.startswith(("═", "The following")):
            current_error = line.strip()[:200]
    return order, failed, errors


def main(folder: Path):
    rows, total_ok, total_fail = [], 0, 0
    for log_file in sorted(folder.glob("*.log")):
        status_file = log_file.with_suffix(".status")
        status = status_file.read_text().strip() if status_file.exists() else "?"
        order, failed, errors = parse(log_file.read_text(errors="replace"))
        if not order:
            rows.append((log_file.stem, "❌", f"não rodou ({status})", ""))
            total_fail += 1
            continue
        for name in order:
            ok = name not in failed
            total_ok += ok
            total_fail += not ok
            # all_test.dart: o teste vem como "<grupo> <nome>", e o grupo é o arquivo de origem.
            suite, test = name.split(" ", 1) if log_file.stem == "e2e" else (log_file.stem, name)
            rows.append((suite, "✅" if ok else "❌", test, "" if ok else errors.get(name, "")))

    lines = ["| Arquivo | | Teste | Erro |", "|---|---|---|---|"]
    lines += [f"| {f} | {icon} | {name} | {error.replace('|', '/')} |" for f, icon, name, error in rows]
    lines += ["", f"**{total_ok} passaram, {total_fail} falharam.** Logs completos em `{folder}`."]
    summary = "\n".join(lines)
    (folder / "resumo.md").write_text(summary + "\n")

    width = max((len(r[2]) for r in rows), default=10)
    print()
    for f, icon, name, error in rows:
        print(f"  {icon} {f:<10} {name:<{width}}  {error}")
    print(f"\n  {total_ok} passaram, {total_fail} falharam — resumo: {folder / 'resumo.md'}")
    return 1 if total_fail else 0


if __name__ == "__main__":
    sys.exit(main(Path(sys.argv[1])))
