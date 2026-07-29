extends Node2D

## Pantalla principal de juego: la puerta del bus, atendiendo
## pasajeros uno por uno. El turno puede tener varias "paradas"
## (LevelData.get_level().stops); al terminar una parada, se repite
## la animación del bus llegando antes de mostrar a los pasajeros de
## la siguiente. Al terminar la última parada, se autoguarda y el
## turno siguiente empieza directo (sin volver a la pantalla de
## Turnos).

const INTRO_SCENE_PATH := "res://scenes/BusArrival.tscn"
const NOVEDAD_SCENE_PATH := "res://scenes/NovedadScreen.tscn"

@onready var dialogue_bar: Control = $DialogueBar
@onready var passenger_sprite: TextureRect = $PassengerSprite

var _stops: Array = []
var _passenger_queue: Array = []
var _current_passenger: Dictionary = {}


func _ready() -> void:
	dialogue_bar.passenger_resolved.connect(_on_passenger_resolved)

	var decisions: Dictionary = SaveManager.get_decisions()
	var day: int = SaveManager.current_save.get("current_day", 1)
	var level: Dictionary = LevelData.get_level(day, decisions)
	_stops = level.get("stops", [])

	var stop_index: int = SaveManager.current_save.get("current_stop_index", 0)
	if stop_index < 0 or stop_index >= _stops.size():
		stop_index = 0

	_passenger_queue = _stops[stop_index].duplicate() if not _stops.is_empty() else []

	_show_next_passenger()


func _show_next_passenger() -> void:
	if _passenger_queue.is_empty():
		_advance_to_next_stop_or_end()
		return

	_current_passenger = _passenger_queue.pop_front()
	dialogue_bar.start_dialogue(_current_passenger)

	var portrait_path: String = _current_passenger.get("portrait", "")
	if portrait_path != "" and ResourceLoader.exists(portrait_path):
		passenger_sprite.texture = load(portrait_path)
	else:
		passenger_sprite.texture = null


func _on_passenger_resolved(result: String) -> void:
	var character_id: String = _current_passenger.get("id", "")
	if character_id != "":
		SaveManager.record_decision(character_id, result)
	_show_next_passenger()


func _advance_to_next_stop_or_end() -> void:
	var stop_index: int = SaveManager.current_save.get("current_stop_index", 0)
	stop_index += 1
	SaveManager.current_save["current_stop_index"] = stop_index

	if stop_index < _stops.size():
		# Quedan más paradas en este turno: repetimos la animación
		# del bus llegando antes de mostrar a los siguientes.
		if ResourceLoader.exists(INTRO_SCENE_PATH):
			get_tree().change_scene_to_file(INTRO_SCENE_PATH)
	else:
		_end_turn()


func _end_turn() -> void:
	SaveManager.end_turn()
	print("[Game] Turno terminado y autoguardado. Comienza el turno ", SaveManager.current_save["current_day"])

	# El turno que empieza ahora puede traer su propia Novedad (noticia
	# del día / explicación de mecánica nueva). Si la tiene, se muestra
	# antes de seguir; si no, se sigue directo como siempre.
	var decisions: Dictionary = SaveManager.get_decisions()
	var next_day: int = SaveManager.current_save.get("current_day", 1)
	var level: Dictionary = LevelData.get_level(next_day, decisions)
	var novedad: Dictionary = level.get("novedad", {})

	if not novedad.is_empty() and ResourceLoader.exists(NOVEDAD_SCENE_PATH):
		get_tree().change_scene_to_file(NOVEDAD_SCENE_PATH)
	else:
		get_tree().reload_current_scene()
