#!/usr/bin/env python3
"""Genere le bloc de releve d'une fiche de niveau depuis le JSON du niveau.

POURQUOI UN GENERATEUR. Le bloc de releve est confronte au fichier de niveau
par `tests/unit/test_design_sheets.gd` : le recopier a la main, c'est
introduire la divergence que ce test existe pour attraper. Il est donc LU du
niveau, jamais saisi.

La PROSE de la fiche reste ecrite a la main, et c'est voulu : le raisonnement
de conception ne se genere pas. Ce script n'ecrit que ce qui pourrit.

    tools/dev/sheet.py ch2_01 docs/design/ch2_01.md   # ecrit, avec garde
    tools/dev/sheet.py ch2_01 --releve                # bloc seul, sur stdout

IL REFUSE D'ECRASER UNE FICHE ECRITE A LA MAIN, et cette garde existe parce
que l'accident a eu lieu : une regeneration en masse a detruit la prose des
cinq fiches du chapitre 1, redigees a la main et irremplacables. L'extraction
de prose de ce script est grossiere — elle recopie l'en-tete du `.lvl` — et
elle n'a de sens que sur les fiches qu'il a lui-meme produites.

Une fiche generee porte donc `MARKER` ; le script refuse d'ecrire par-dessus
un fichier qui ne l'a pas. Documenter la prudence n'aurait protege de rien :
c'est exactement ce que le depot a appris trois fois.
"""

import json
import sys
from pathlib import Path

## Marque de generation. Une fiche qui ne la porte PAS a ete ecrite a la main,
## et le script refuse alors d'ecrire par-dessus.
MARKER = "genere par `tools/dev/sheet.py`"

ROOT = Path(__file__).resolve().parents[2]


def record(level_id: str) -> dict:
    d = json.loads((ROOT / f"data/levels/{level_id}.json").read_text())
    return {
        "id": d["id"],
        "agents": len(d["agents"]),
        "grid": d["grid"]["size"],
        "slots": d["slots"],
        "allowed_rules": d["allowed_rules"],
        "expected_wins": d.get("expected_wins", -1),
        "expected_classes": d.get("expected_classes", -1),
        "calibrated_on": d.get("calibrated_on", ""),
    }


def objectives(level_id: str) -> str:
    d = json.loads((ROOT / f"data/levels/{level_id}.json").read_text())
    parts = []
    for o in d.get("objectives", []):
        t = o["type"]
        if t == "extraction":
            parts.append(f"`extraction {o.get('percent', 100)}`")
        elif t == "celerity":
            parts.append(f"`celerity {o.get('max_ticks')}`")
        elif t == "preservation":
            parts.append(f"`preservation {o.get('max_lost')}`")
        elif t == "collect":
            parts.append(f"`collect {o.get('count')}`")
        elif t == "interdiction":
            parts.append(f"`interdiction ({len(o.get('cells', []))} cases)`")
    return " · ".join(parts) if parts else "aucun"


def main() -> int:
    if len(sys.argv) < 2:
        print(__doc__, file=sys.stderr)
        return 2
    level_id = sys.argv[1]
    block = "```json\n" + json.dumps(record(level_id), indent=2, ensure_ascii=False) + "\n```"
    if "--releve" in sys.argv:
        print(block)
        return 0
    target = None
    for arg in sys.argv[2:]:
        if not arg.startswith("--"):
            target = Path(arg)
    if target is not None and target.exists():
        if MARKER not in target.read_text():
            print(
                f"REFUS — {target} ne porte pas la marque de generation.\n"
                "Cette fiche a ete ecrite a la main : la regenerer detruirait sa prose.\n"
                "Mettre a jour son bloc de releve avec `--releve`, et le coller.",
                file=sys.stderr,
            )
            return 1
    lvl = (ROOT / f"data/levels/{level_id}.lvl").read_text()
    header = lvl.split("---\n", 1)[0]
    prose = "\n".join(
        line[2:] if line.startswith("# ") else line.lstrip("#")
        for line in header.splitlines()
        if line.startswith("#")
    )
    name = next((l.split(":", 1)[1].strip() for l in header.splitlines()
                 if l.startswith("name:")), level_id)
    lesson = next((l.split(":", 1)[1].strip().strip('"') for l in header.splitlines()
                   if l.startswith("lesson:")), "")
    text = f"""# Fiche de niveau — {level_id} « {name} »

> **Statut : CONSTRUIT ET VALIDE.** Source : `data/levels/{level_id}.lvl`.
> Cette fiche est un **releve**, pas une proposition : le bloc ci-dessous est
> confronte au fichier de niveau par `tests/unit/test_design_sheets.gd`. Il est
> {MARKER}, jamais recopie a la main — une fiche perimee n'est pas un document
> incomplet, c'est une source qui ment.

## Ce que le niveau enseigne

**{lesson}**

## Le dispositif

{prose}

## Releve

Objectifs : {objectives(level_id)}

{block}"""
    if target is not None:
        target.write_text(text + "\n")
    else:
        print(text)
    return 0


if __name__ == "__main__":
    sys.exit(main())
