extends Node

## SaveManager (Autoload / Singleton)
## Maneja el guardado automático de la partida, un turno/día a la vez,
## igual que en Papers, Please: no hay botón de "Guardar" manual, el
## juego se autoguarda al terminar cada turno.
##
## IMPORTANTE: este script debe registrarse como Autoload en
## Proyecto > Configuración del Proyecto > pestaña "Autoload",
## con el nombre "SaveManager" apuntando a este archivo.
## Una vez registrado, se puede llamar desde cualquier script
## del juego simplemente escribiendo SaveManager.algo(), sin
## necesidad de @onready ni rutas.

const SAVE_PATH := "user://savegame.json"

## MODO REPASO: permite volver a jugar un turno ya completado (por
## ejemplo para conseguir un logro que se pasó por alto), sin tocar
## la partida real para nada. Estas 3 variables viven APARTE de
## current_save a propósito — nunca se escriben en el archivo de
## guardado, así que no hay forma de que un repaso contamine la
## partida real, ni aunque el juego se cierre a la mitad de uno.
var review_mode: bool = false
var review_day: int = 0
var review_stop_index: int = 0


func start_review(day: int) -> void:
	review_mode = true
	review_day = day
	review_stop_index = 0


func end_review() -> void:
	review_mode = false
	review_day = 0
	review_stop_index = 0

## Cuánto sube o baja la Confianza del pueblo según la categoría del
## pasajero y qué se decidió con él. Categorías que no están en esta
## tabla (D, E, F, G, etc.) todavía no afectan la Confianza — se
## manejarán caso por caso más adelante, cuando tengan mecánicas
## propias.
const CONFIANZA_IMPACT := {
	"A": {"pasar": 2, "vete": -5},   # comunes/inocentes: negarles duele mucho
	"B": {"pasar": 1, "vete": -2},   # con secreto: sospechosos, pero no se sabe si son culpables
	"C": {"pasar": -5, "vete": 3},   # peligrosos: al revés, dejarlos pasar es lo grave
}
const CONFIANZA_DEFAULT_IMPACT := {"pasar": 0, "vete": 0}

## Cuánto dinero deja cada decisión, también según categoría. Por
## ahora solo los pasajeros C (peligrosos) sueltan dinero, porque
## representan sobornos: dejarlos pasar ("pasar") es aceptar la
## plata, no dejarlos ("vete") es rechazarla.
const AHORROS_IMPACT := {
	"C": {"pasar": 10000000, "vete": 0},
}
const AHORROS_DEFAULT_IMPACT := {"pasar": 0, "vete": 0}

## Meta de ahorros para poder comprar la finca. Referencia para la
## barra de progreso en la pantalla de Turnos.
const AHORROS_GOAL := 125000000

## Estructura de datos de la partida actual.
##
## "turn_history" guarda un registro de cada turno/día ya jugado y
## terminado, en orden (para la pantalla de Turnos).
##
## "decisions" guarda, por personaje (usando su "id"), qué resultado
## tuvo la ÚLTIMA vez que se le atendió ("pasar" o "vete"). Se
## mantiene entre turnos para que el diálogo de un personaje pueda
## cambiar según lo que el jugador decidió con él anteriormente
## (ej: el estudiante cuenta si perdió o no el examen).
##
## "decision_log" guarda, también por personaje, el HISTORIAL
## completo de resultados en orden (no solo el último). Sirve para
## personajes cuyo diálogo depende de varias decisiones pasadas a
## la vez (ej: Stuard reacciona distinto según lo que pasó en los
## últimos dos turnos, no solo el más reciente).
##
## "current_stop_index" indica en qué parada del turno actual va el
## jugador (0 = primera parada). Se reinicia a 0 cada vez que
## empieza un turno nuevo.
##
## "confianza" es la Confianza del pueblo (0 a 100, arranca en 50).
## Sube o baja según las decisiones del jugador con cada pasajero, y
## se muestra en la pantalla de Turnos como palabra, no como número.
##
## "ahorros" es la plata ahorrada para la finca (empieza en 0). Por
## ahora solo sube con los sobornos de pasajeros peligrosos (C). Se
## muestra en la pantalla de Turnos con una barra de progreso hacia
## AHORROS_GOAL.
##
## "quejas" es una lista de quejas formales que ha recibido el
## cobrador (ej: por rechazar a alguien sin una razón de seguridad
## válida). Cada una queda con el día en que pasó y el motivo, para
## poder usarlas más adelante en la historia (ej: que una noticia
## futura confirme si la sospecha era o no correcta). No se muestra
## como contador en pantalla — en su lugar, el juego muestra un
## mensaje corto (ver Game.gd) en el momento en que pasa.
##
## "affinity" guarda, por personaje, qué tan buena onda te tiene
## (empieza en 0). Sirve para personajes recurrentes como Eugenio:
## dejarlo pasar Y preguntarle algo lo acerca más; no dejarlo pasar,
## o dejarlo pasar sin nunca preguntarle nada, hace que te empiece a
## caer mal.
var current_save: Dictionary = {
	"current_day": 1,
	"score": 0,
	"last_saved": "",
	"turn_history": [],
	"decisions": {},
	"decision_log": {},
	"current_stop_index": 0,
	"confianza": 50,
	"ahorros": 0,
	"quejas": [],
	"affinity": {},
}


func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func save_game() -> void:
	current_save["last_saved"] = Time.get_datetime_string_from_system()
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("[SaveManager] No se pudo abrir el archivo para guardar.")
		return
	file.store_string(JSON.stringify(current_save, "\t"))
	file.close()
	print("[SaveManager] Partida guardada. Día actual: ", current_save["current_day"])


func load_game() -> bool:
	if not has_save():
		return false
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_error("[SaveManager] No se pudo abrir el archivo para cargar.")
		return false
	var text := file.get_as_text()
	file.close()
	var parsed = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("[SaveManager] El archivo de guardado está corrupto.")
		return false
	current_save = parsed

	# Por si se carga una partida vieja guardada antes de que
	# existieran estos campos.
	if not current_save.has("decisions"):
		current_save["decisions"] = {}
	if not current_save.has("decision_log"):
		current_save["decision_log"] = {}
	if not current_save.has("current_stop_index"):
		current_save["current_stop_index"] = 0
	if not current_save.has("confianza"):
		current_save["confianza"] = 50
	if not current_save.has("ahorros"):
		current_save["ahorros"] = 0
	if not current_save.has("quejas"):
		current_save["quejas"] = []
	if not current_save.has("affinity"):
		current_save["affinity"] = {}

	print("[SaveManager] Partida cargada. Día actual: ", current_save["current_day"])
	return true


func start_new_game() -> void:
	current_save = {
		"current_day": 1,
		"score": 0,
		"last_saved": "",
		"turn_history": [],
		"decisions": {},
		"decision_log": {},
		"current_stop_index": 0,
		"confianza": 50,
		"ahorros": 0,
		"quejas": [],
		"affinity": {},
	}


func delete_save() -> void:
	if has_save():
		DirAccess.remove_absolute(SAVE_PATH)


func record_decision(character_id: String, result: String) -> void:
	## Guarda qué se decidió con este personaje ("pasar" o "vete"),
	## para que la próxima vez que aparezca (en otro turno) su
	## diálogo pueda reaccionar a eso. También lo agrega al
	## historial completo de ese personaje (decision_log), para
	## personajes cuyo diálogo depende de más de una decisión pasada.
	if character_id == "":
		return
	if not current_save.has("decisions"):
		current_save["decisions"] = {}
	current_save["decisions"][character_id] = result

	if not current_save.has("decision_log"):
		current_save["decision_log"] = {}
	if not current_save["decision_log"].has(character_id):
		current_save["decision_log"][character_id] = []
	current_save["decision_log"][character_id].append(result)


func get_decisions() -> Dictionary:
	if not current_save.has("decisions"):
		current_save["decisions"] = {}
	return current_save["decisions"]


func get_decision_log() -> Dictionary:
	if not current_save.has("decision_log"):
		current_save["decision_log"] = {}
	return current_save["decision_log"]


func apply_confianza_change(category: String, result: String) -> void:
	## Ajusta la Confianza del pueblo según la categoría del pasajero
	## (A, B, C...) y lo que se decidió ("pasar" o "vete"). Categorías
	## sin tabla propia no afectan la Confianza todavía.
	if not current_save.has("confianza"):
		current_save["confianza"] = 50
	var impact_table: Dictionary = CONFIANZA_IMPACT.get(category, CONFIANZA_DEFAULT_IMPACT)
	var change: int = impact_table.get(result, 0)
	current_save["confianza"] = clampi(current_save["confianza"] + change, 0, 100)


func get_confianza() -> int:
	if not current_save.has("confianza"):
		current_save["confianza"] = 50
	return current_save["confianza"]


func get_confianza_label() -> String:
	## Traduce el número interno de Confianza a la palabra que se
	## muestra en pantalla (nunca se ve el número).
	var value: int = get_confianza()
	if value >= 80:
		return "Muy confiable"
	elif value >= 60:
		return "Confiable"
	elif value >= 40:
		return "Neutral"
	elif value >= 20:
		return "Sospechoso"
	else:
		return "Odiado"


func apply_ahorros_change(category: String, result: String) -> void:
	## Ajusta los ahorros según la categoría del pasajero y lo que se
	## decidió. Por ahora solo los C (peligrosos) sueltan soborno.
	if not current_save.has("ahorros"):
		current_save["ahorros"] = 0
	var impact_table: Dictionary = AHORROS_IMPACT.get(category, AHORROS_DEFAULT_IMPACT)
	var change: int = impact_table.get(result, 0)
	current_save["ahorros"] = max(0, current_save["ahorros"] + change)


func get_ahorros() -> int:
	if not current_save.has("ahorros"):
		current_save["ahorros"] = 0
	return current_save["ahorros"]


func get_ahorros_progress() -> float:
	## De 0.0 a 1.0, para la barra de progreso hacia la finca.
	return clampf(float(get_ahorros()) / float(AHORROS_GOAL), 0.0, 1.0)


func record_queja(character_name: String, reason: String) -> void:
	## Registra una queja formal contra el cobrador (ej: rechazar a
	## alguien sin una razón de seguridad válida). Queda con el día
	## en que pasó, para poder usarla más adelante en la historia.
	if not current_save.has("quejas"):
		current_save["quejas"] = []
	current_save["quejas"].append({
		"day": current_save.get("current_day", 1),
		"character_name": character_name,
		"reason": reason,
	})


func get_quejas() -> Array:
	if not current_save.has("quejas"):
		current_save["quejas"] = []
	return current_save["quejas"]


func get_quejas_count() -> int:
	return get_quejas().size()


func apply_affinity_change(character_id: String, delta: int) -> void:
	if not current_save.has("affinity"):
		current_save["affinity"] = {}
	var current: int = current_save["affinity"].get(character_id, 0)
	current_save["affinity"][character_id] = clampi(current + delta, -10, 10)


func get_affinity_value(character_id: String) -> int:
	if not current_save.has("affinity"):
		current_save["affinity"] = {}
	return current_save["affinity"].get(character_id, 0)


func get_affinity_label(character_id: String) -> String:
	var value: int = get_affinity_value(character_id)
	if value >= 6:
		return "amigo"
	elif value >= 2:
		return "simpatiza"
	elif value >= -1:
		return "neutral"
	elif value >= -5:
		return "distante"
	else:
		return "le_caes_mal"


func end_turn() -> void:
	## Llamar esta función justo cuando termina cada turno/día de juego
	## (cuando ya se atendió la última parada). Registra el turno
	## recién completado en el historial, avanza el contador de día,
	## reinicia la parada para el turno siguiente, y autoguarda.
	if not current_save.has("turn_history"):
		current_save["turn_history"] = []

	current_save["turn_history"].append({
		"day": current_save["current_day"],
		"date": Time.get_datetime_string_from_system(),
		"confianza_label": get_confianza_label(),
	})

	current_save["current_day"] += 1
	current_save["current_stop_index"] = 0
	save_game()


func get_turn_history() -> Array:
	## Devuelve la lista de turnos ya completados, del más antiguo
	## al más reciente. La usa la pantalla de Turnos para armar el
	## listado en pantalla.
	if not current_save.has("turn_history"):
		return []
	return current_save["turn_history"]
