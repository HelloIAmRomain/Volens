#!/usr/bin/env python3
"""Genere le bloc de releve d'une fiche de niveau depuis le JSON du niveau.

POURQUOI UN GENERATEUR. Le bloc de releve est confronte au fichier de niveau
par `tests/unit/test_design_sheets.gd` : le recopier a la main, c'est
introduire la divergence que ce test existe pour attraper. Il est donc LU du
niveau, jamais saisi.

La PROSE de la fiche reste ecrite a la main, et c'est voulu : le raisonnement
de conception ne se genere pas. Ce script n'ecrit que ce qui pourrit.

    tools/dev/sheet.py ch2_01 > docs/design/ch2_01.md   # nouvelle fiche
    tools/dev/sheet.py ch2_01 --releve                  # bloc seul
"""
import json
import sys
from pathlib import Path

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
    print(f"""# Fiche de niveau — {level_id} « {name} »

> **Statut : CONSTRUIT ET VALIDE.** Source : `data/levels/{level_id}.lvl`.
> Cette fiche est un **releve**, pas une proposition : le bloc ci-dessous est
> confronte au fichier de niveau par `tests/unit/test_design_sheets.gd`. Il est
> genere par `tools/dev/sheet.py`, jamais recopie a la main — une fiche perimee
> n'est pas un document incomplet, c'est une source qui ment.

## Ce que le niveau enseigne

**{lesson}**

## Le dispositif

{prose}

## Releve

Objectifs : {objectives(level_id)}

{block}""")
    return 0


if __name__ == "__main__":
    sys.exit(main())
