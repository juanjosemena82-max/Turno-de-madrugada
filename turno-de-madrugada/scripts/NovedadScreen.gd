extends Control

## Pantalla de "Novedad": se muestra antes de empezar un turno que
## tiene noticias del día y/o una nueva mecánica que explicar.
## TurnsScreen decide si hay que pasar por aquí o ir directo al bus,
## según si LevelData.get_level() trae algo en "novedad".

const INTRO_SCENE_PATH := "res://scenes/BusArrival.tscn"

@onready var news_label: Label = $NewsLabel
@onready var mechanics_label: Label = $MechanicsLabel
@onready var continue_button: Button = $ContinueButton


func _ready() -> void:
	continue_button.pressed.connect(_on_continue_pressed)

	var decisions: Dictionary = SaveManager.get_decisions()
	var day: int = SaveManager.current_save.get("current_day", 1)
	var level: Dictionary = LevelData.get_level(day, decisions)
	var novedad: Dictionary = level.get("novedad", {})

	print("[NovedadScreen] day=", day, " novedad=", novedad)

	news_label.text = novedad.get("news", "")
	mechanics_label.text = novedad.get("mechanics", "")


func _on_continue_pressed() -> void:
	if ResourceLoader.exists(INTRO_SCENE_PATH):
		get_tree().change_scene_to_file(INTRO_SCENE_PATH)
