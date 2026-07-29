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
## "current_stop_index" indica en qué parada del turno actual va el
## jugador (0 = primera parada). Se reinicia a 0 cada vez que
## empieza un turno nuevo.
var current_save: Dictionary = {
	"current_day": 1,
	"score": 0,
	"last_saved": "",
	"turn_history": [],
	"decisions": {},
	"current_stop_index": 0,
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
	if not current_save.has("current_stop_index"):
		current_save["current_stop_index"] = 0

	print("[SaveManager] Partida cargada. Día actual: ", current_save["current_day"])
	return true


func start_new_game() -> void:
	current_save = {
		"current_day": 1,
		"score": 0,
		"last_saved": "",
		"turn_history": [],
		"decisions": {},
		"current_stop_index": 0,
	}


func delete_save() -> void:
	if has_save():
		DirAccess.remove_absolute(SAVE_PATH)


func record_decision(character_id: String, result: String) -> void:
	## Guarda qué se decidió con este personaje ("pasar" o "vete"),
	## para que la próxima vez que aparezca (en otro turno) su
	## diálogo pueda reaccionar a eso.
	if character_id == "":
		return
	if not current_save.has("decisions"):
		current_save["decisions"] = {}
	current_save["decisions"][character_id] = result


func get_decisions() -> Dictionary:
	if not current_save.has("decisions"):
		current_save["decisions"] = {}
	return current_save["decisions"]


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
		"score": current_save["score"],
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
