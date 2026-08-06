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

## Moitié basse réservée au pouce (ENF-01) : la pile et le transport n'en
## sortent jamais. La grille occupe ce qui reste au-dessus.
const THUMB_ZONE_RATIO := 0.42

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
