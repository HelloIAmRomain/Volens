#!/usr/bin/env python3
"""Édition ancrée de fichiers existants, qui ÉCHOUE BRUYAMMENT.

POURQUOI CE SCRIPT EXISTE. Trois fois, un correctif appliqué par un
`str.replace` dont l'ancre ne correspondait pas a été rapporté comme un
succès : le fichier n'était pas modifié, rien ne le disait, et le défaut a
survécu à sa propre correction. Un outil qui peut ne rien remplacer et
renvoyer un succès n'est pas utilisable sur du code existant.

Ici, toute ancre doit correspondre EXACTEMENT au nombre d'occurrences
attendu. Sinon : rien n'est écrit, le détail part sur stderr, code de
sortie 1.

Usage :
    tools/dev/patch.py <fichier> <edits.json>
    tools/dev/patch.py <fichier> -            # edits.json sur stdin

edits.json : [{"old": "...", "new": "...", "count": 1}, ...]
`count` vaut 1 par défaut ; mettre le nombre exact pour un remplacement
multiple. Les ancres sont appliquées dans l'ordre, chacune vérifiée sur
l'état courant du texte.
"""
import json
import sys
from pathlib import Path


def main() -> int:
    if len(sys.argv) != 3:
        print(__doc__, file=sys.stderr)
        return 2

    target = Path(sys.argv[1])
    if not target.is_file():
        print(f"patch: fichier introuvable : {target}", file=sys.stderr)
        return 1

    raw = sys.stdin.read() if sys.argv[2] == "-" else Path(sys.argv[2]).read_text("utf-8")
    edits = json.loads(raw)
    if not isinstance(edits, list) or not edits:
        print("patch: edits.json doit être une liste non vide", file=sys.stderr)
        return 2

    text = original = target.read_text("utf-8")
    failures = []

    for i, edit in enumerate(edits, 1):
        old = edit["old"]
        new = edit["new"]
        expected = int(edit.get("count", 1))
        found = text.count(old)
        if found != expected:
            head = old.strip().splitlines()[0][:70] if old.strip() else "(vide)"
            failures.append(
                f"  edit #{i} : {found} occurrence(s), {expected} attendue(s) — ancre « {head} »"
            )
            continue
        text = text.replace(old, new)

    if failures:
        print(f"patch: AUCUNE ÉCRITURE dans {target} — {len(failures)} ancre(s) en échec :",
              file=sys.stderr)
        print("\n".join(failures), file=sys.stderr)
        return 1

    if text == original:
        print(f"patch: {target} inchangé (les remplacements sont sans effet)", file=sys.stderr)
        return 1

    target.write_text(text, "utf-8")
    print(f"patch: {target} — {len(edits)} édition(s) appliquée(s)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
