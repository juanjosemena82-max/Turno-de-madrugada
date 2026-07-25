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

## Estructura de datos de la partida actual. La iremos ampliando más
## adelante con historial de pasajeros, decisiones tomadas, etc.
var current_save: Dictionary = {
	"current_day": 1,
	"score": 0,
	"last_saved": "",
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
	print("[SaveManager] Partida cargada. Día actual: ", current_save["current_day"])
	return true


func start_new_game() -> void:
	current_save = {
		"current_day": 1,
		"score": 0,
		"last_saved": "",
	}


func delete_save() -> void:
	if has_save():
		DirAccess.remove_absolute(SAVE_PATH)


func end_turn() -> void:
	## Llamar esta función justo cuando termina cada turno/día de juego
	## (por ejemplo, cuando el último bus del turno se va). Avanza el
	## contador de día y dispara el autoguardado.
	current_save["current_day"] += 1
	save_game()
