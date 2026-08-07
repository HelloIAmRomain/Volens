class_name UiMetrics
extends RefCounted
## Constantes de disposition de l'interface de jeu [DCT §9.2, ENF-01].
##
## CIBLE TACTILE MINIMALE — la valeur est dérivée, pas choisie.
## ENF-01 exige ≈ 48 dp. La résolution de base du projet est 1080×2400 en
## étirement `canvas_items` : les unités de l'interface sont donc les pixels
## de cette base, quelle que soit la dalle réelle. Sur les appareils visés,
## 1080 px de large correspondent à 360 dp (densité 3,0) à 411 dp (S23
## Ultra, densité ~2,63). Une unité vaut donc entre 0,33 et 0,38 dp, et
## 48 dp valent entre 126 et 144 unités. On retient **144**, la borne haute :
## une cible trop grande ne viole aucune exigence, une cible trop petite si.
const MIN_TOUCH_TARGET := 144.0

## ATTEIGNABILITÉ AU POUCE — mesurée, pas estimée (7 août 2026).
##
## Appareil de référence : Galaxy S23 Ultra, 6,8 pouces en 19,3:9, soit une
## dalle d'environ 156 mm de haut sur 73 mm de large. En prise à une main, le
## pouce pivote près du coin bas et décrit un arc : rayon confortable
## d'environ 90 mm, rayon d'extension maximale d'environ 110 mm pour une main
## adulte moyenne.
##
## Sur la hauteur, en unités de la base 1080x2400 :
##   · y > 1080 (moitié basse)      → zone CONFORTABLE (90 mm depuis le bas) ;
##   · 720 < y <= 1080              → zone d'EXTENSION, atteignable en tendant ;
##   · y <= 720 (tiers supérieur)   → HORS DE PORTÉE sans changer de prise.
##
## Conséquence opposable : rien de critique au-dessus de `REACH_LIMIT`, et
## toute commande qu'on y place doit avoir un **second chemin** dans la zone
## confortable. Ce n'est pas une préférence, c'est ENF-01.
const REACH_COMFORT := 1080.0
const REACH_LIMIT := 720.0

## Moitié basse réservée au pouce (ENF-01) : la pile n'en sort jamais.
const THUMB_ZONE_RATIO := 0.42

## Discrimination des gestes sur un même appui maintenu. Deux gestes seulement
## dans le jeu — sélection et glissement, plus l'appui long pour l'explication.
## (La surcouche de diagnostic par appui long vit dans le banc, pas ici : la
## discrimination reste donc à deux voies dans l'écran de jeu.)
## Seuil de mouvement en unités de la base 1080 : ~8 dp, assez large pour
## absorber le tremblement d'une main dans un bus, assez court pour qu'un
## glissement volontaire soit reconnu tout de suite.
const DRAG_THRESHOLD := 24.0
const LONG_PRESS_SECONDS := 0.45

const MARGIN := 36.0
const GAP := 24.0
const SLOT_COUNT := 4  # RG-05 : la pile compte quatre emplacements

## Marges de zone sûre (encoches, barre gestuelle). Sur ordinateur la zone
## sûre couvre toute la fenêtre : la fonction est alors sans effet.
static func safe_area_margins(viewport_size: Vector2) -> Vector4:
	var safe := DisplayServer.get_display_safe_area()
	var screen := DisplayServer.screen_get_size()
	if screen.x <= 0 or screen.y <= 0 or safe.size.x <= 0:
		return Vector4(MARGIN, MARGIN, MARGIN, MARGIN)
	var sx: float = viewport_size.x / float(screen.x)
	var sy: float = viewport_size.y / float(screen.y)
	return Vector4(
		maxf(MARGIN, safe.position.x * sx),
		maxf(MARGIN, safe.position.y * sy),
		maxf(MARGIN, (screen.x - safe.position.x - safe.size.x) * sx),
		maxf(MARGIN, (screen.y - safe.position.y - safe.size.y) * sy))
