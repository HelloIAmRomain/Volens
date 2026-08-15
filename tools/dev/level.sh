#!/usr/bin/env bash
# Boucle d'écriture d'un niveau : convertir, calibrer, valider, résumer.
#
# POURQUOI CE SCRIPT. Écrire un niveau demande cinq gestes dans le même ordre,
# et l'un d'eux — inscrire `calibrated_on` — ne peut pas être fait avant que le
# convertisseur ait calculé l'empreinte. Le faire à la main vingt-cinq fois,
# c'est vingt-cinq occasions de coller la mauvaise empreinte sur le mauvais
# niveau, et l'invariant n°15 ne protège alors plus rien.
#
# Le script écrit `calibrated_on` UNIQUEMENT si la valeur actuelle est
# PLACEHOLDER : il ne réétalonne jamais un niveau déjà calibré en silence.
# Un niveau dont la géométrie a bougé doit être remesuré par une personne, et
# le convertisseur continue de le refuser jusque-là.
#
#   tools/dev/level.sh ch2_01
set -u
cd "$(dirname "$0")/../.."
GODOT="${GODOT:-$HOME/bin/godot}"
LVL="data/levels/$1.lvl"

[ -f "$LVL" ] || { echo "introuvable : $LVL"; exit 2; }

if grep -q "^calibrated_on: PLACEHOLDER" "$LVL"; then
	FP=$("$GODOT" --headless --path . --script res://tools/lvl/run.gd -- --in="$LVL" 2>&1 \
		| grep -oE "la grille actuelle vaut [0-9a-f]{16}" | grep -oE "[0-9a-f]{16}")
	if [ -n "$FP" ]; then
		python3 tools/dev/patch.py "$LVL" - <<EOF
[{"old": "calibrated_on: PLACEHOLDER", "new": "calibrated_on: $FP"}]
EOF
	fi
fi

"$GODOT" --headless --path . --script res://tools/lvl/run.gd -- --in="$LVL" 2>&1 \
	| grep -E "✗|⚠|Converti" | sed 's/^/  /'
"$GODOT" --headless --path . --script res://tools/validate/run.gd -- --level="$1" 2>&1 \
	| grep -E "gagnantes|fiche|efficience|defis|verdict|sur-place|proches" | sed 's/^/  /'
echo "  --- piles ---"
awk -F';' 'NR>1 && $2=="WON" {printf "  GAGNE  %-12s %3s ticks  %s sortis\n",$1,$3,$4}' \
	"reports/validate/$1.csv" 2>/dev/null
awk -F';' 'NR>1 && $2!="WON" {printf "  perdu  %-12s %3s ticks  %s sortis  %s perdus  %s bloques\n",$1,$3,$4,$5,$8}' \
	"reports/validate/$1.csv" 2>/dev/null | head -14
