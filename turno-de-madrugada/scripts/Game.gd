extends Node2D

## Pantalla principal de juego: la puerta del bus, atendiendo
## pasajeros uno por uno. El turno puede tener varias "paradas"
## (LevelData.get_level().stops); al terminar una parada, se repite
## la animación del bus llegando antes de mostrar a los pasajeros de
## la siguiente. Al terminar la última parada, se autoguarda y el
## turno siguiente empieza directo (sin volver a la pantalla de
## Turnos).
##
## MODO REPASO: si SaveManager.review_mode está activo, esta escena
## usa SaveManager.review_day / review_stop_index en vez del día y
## la parada reales, y NINGUNA decisión que tomes aquí se guarda
## (ni Confianza, ni Ahorros, ni Amistad, ni el historial). Al
## terminar el turno repasado, se vuelve directo a la pantalla de
## Turnos sin tocar la partida real.

const INTRO_SCENE_PATH := "res://scenes/BusArrival.tscn"
const NOVEDAD_SCENE_PATH := "res://scenes/NovedadScreen.tscn"
const TURNS_SCENE_PATH := "res://scenes/TurnsScreen.tscn"

@onready var dialogue_bar: Control = $DialogueBar
@onready var passenger_sprite: TextureRect = $PassengerSprite
@onready var toast_label: Label = $ToastLabel
@onready var review_banner: Label = $ReviewBanner

## Personajes cuya relación con el jugador se rastrea con el sistema
## de Amistad (Confianza es sobre el pueblo en general; esto es más
## personal, uno a uno). Por ahora solo Eugenio.
const TRACKED_AFFINITY_CHARACTERS := ["eugenio_escobar"]

var _stops: Array = []
var _passenger_queue: Array = []
var _current_passenger: Dictionary = {}


func _ready() -> void:
	dialogue_bar.passenger_resolved.connect(_on_passenger_resolved)
	toast_label.text = ""
	review_banner.visible = SaveManager.review_mode

	var decisions: Dictionary = SaveManager.get_decisions()
	var decision_log: Dictionary = SaveManager.get_decision_log()
	var day: int = SaveManager.review_day if SaveManager.review_mode else SaveManager.current_save.get("current_day", 1)
	var level: Dictionary = LevelData.get_level(day, decisions, decision_log)
	_stops = level.get("stops", [])

	var stop_index: int = SaveManager.review_stop_index if SaveManager.review_mode else SaveManager.current_save.get("current_stop_index", 0)
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


func _on_passenger_resolved(result: String, asked_question: bool) -> void:
	# En modo repaso no se guarda absolutamente nada: ni decisiones,
	# ni Confianza, ni Ahorros, ni Amistad, ni quejas. Solo se
	# muestra el mensaje flotante si aplica, como parte normal de la
	# escena que se está repasando.
	if not SaveManager.review_mode:
		var character_id: String = _current_passenger.get("id", "")
		if character_id != "":
			SaveManager.record_decision(character_id, result)

		var category: String = _current_passenger.get("category", "")
		if category != "":
			SaveManager.apply_confianza_change(category, result)
			SaveManager.apply_ahorros_change(category, result)

		if character_id in TRACKED_AFFINITY_CHARACTERS:
			_apply_affinity_from_interaction(character_id, result, asked_question)

		var complaint_reason: String = _current_passenger.get("complaint_if_denied", "")
		if result == "vete" and complaint_reason != "":
			SaveManager.record_queja(_current_passenger.get("name", ""), complaint_reason)

		var allowed_complaint: String = _current_passenger.get("complaint_if_allowed", "")
		if result == "pasar" and allowed_complaint != "":
			SaveManager.record_queja(_current_passenger.get("name", ""), allowed_complaint)
			_show_toast(allowed_complaint)

		# Algunos pasajeros traen documentos/cartas que hay que
		# verificar (usar "Preguntar" para leerlos) antes de dejarlos
		# subir. Si se deja pasar sin haber preguntado nada, la
		# empresa registra el error aunque el pasajero esté bien.
		if _current_passenger.get("requires_verification", false) and result == "pasar" and not asked_question:
			SaveManager.apply_confianza_change("A", "vete") # mismo castigo que negarle a un inocente
			_show_toast("La empresa registra un error: dejaste subir sin verificar los documentos.")

	if result == "vete":
		var denial_reaction: String = _current_passenger.get("denial_reaction", "")
		if denial_reaction != "":
			_show_toast(denial_reaction)

	_show_next_passenger()


func _apply_affinity_from_interaction(character_id: String, result: String, asked_question: bool) -> void:
	## Dejarlo pasar Y preguntarle algo lo acerca. No dejarlo pasar,
	## o dejarlo pasar sin nunca preguntarle nada, hace que se vaya
	## enfriando la relación.
	if result == "vete":
		SaveManager.apply_affinity_change(character_id, -3)
	elif asked_question:
		SaveManager.apply_affinity_change(character_id, 2)
	else:
		SaveManager.apply_affinity_change(character_id, -1)


func _show_toast(text: String) -> void:
	toast_label.text = text
	toast_label.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(toast_label, "modulate:a", 1.0, 0.3)
	tween.tween_interval(3.0)
	tween.tween_property(toast_label, "modulate:a", 0.0, 0.6)


func _advance_to_next_stop_or_end() -> void:
	if SaveManager.review_mode:
		SaveManager.review_stop_index += 1
		if SaveManager.review_stop_index < _stops.size():
			if ResourceLoader.exists(INTRO_SCENE_PATH):
				get_tree().change_scene_to_file(INTRO_SCENE_PATH)
		else:
			_end_review()
		return

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


func _end_review() -> void:
	## Se acabó el turno repasado: no se guarda nada, se vuelve
	## directo a la pantalla de Turnos.
	SaveManager.end_review()
	if ResourceLoader.exists(TURNS_SCENE_PATH):
		get_tree().change_scene_to_file(TURNS_SCENE_PATH)


func _end_turn() -> void:
	SaveManager.end_turn()
	print("[Game] Turno terminado y autoguardado. Comienza el turno ", SaveManager.current_save["current_day"])

	# El turno que empieza ahora puede traer su propia Novedad (noticia
	# del día / explicación de mecánica nueva). Si la tiene, se muestra
	# antes de seguir; si no, se sigue directo como siempre.
	var decisions: Dictionary = SaveManager.get_decisions()
	var decision_log: Dictionary = SaveManager.get_decision_log()
	var next_day: int = SaveManager.current_save.get("current_day", 1)
	var level: Dictionary = LevelData.get_level(next_day, decisions, decision_log)
	var novedad: Dictionary = level.get("novedad", {})

	if not novedad.is_empty() and ResourceLoader.exists(NOVEDAD_SCENE_PATH):
		get_tree().change_scene_to_file(NOVEDAD_SCENE_PATH)
	else:
		get_tree().reload_current_scene()
