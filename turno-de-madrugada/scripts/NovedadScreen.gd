extends Control

## Pantalla de "Novedad": se muestra antes de empezar un turno que
## tiene noticias del día y/o una nueva mecánica que explicar, y
## también indica en qué tramo de la ruta va este turno.
## TurnsScreen decide si hay que pasar por aquí o ir directo al bus,
## según si LevelData.get_level() trae algo en "novedad".

const INTRO_SCENE_PATH := "res://scenes/BusArrival.tscn"

@onready var news_label: Label = $NewsLabel
@onready var mechanics_label: Label = $MechanicsLabel
@onready var route_label: Label = $RouteLabel
@onready var continue_button: Button = $ContinueButton


func _ready() -> void:
	continue_button.pressed.connect(_on_continue_pressed)

	var decisions: Dictionary = SaveManager.get_decisions()
	var decision_log: Dictionary = SaveManager.get_decision_log()
	var day: int = SaveManager.current_save.get("current_day", 1)
	var level: Dictionary = LevelData.get_level(day, decisions, decision_log)
	var novedad: Dictionary = level.get("novedad", {})
	var route: String = level.get("route", "")

	news_label.text = novedad.get("news", "")
	mechanics_label.text = novedad.get("mechanics", "")
	route_label.text = "Ruta: " + _route_display_text(route)


func _route_display_text(route: String) -> String:
	match route:
		"cali_vijes":
			return "Cali → Vijes"
		"vijes_cali":
			return "Vijes → Cali"
		_:
			return ""


func _on_continue_pressed() -> void:
	if ResourceLoader.exists(INTRO_SCENE_PATH):
		get_tree().change_scene_to_file(INTRO_SCENE_PATH)
