extends Control

## Menú principal de "Turno de Madrugada"
## Por ahora solo maneja la interfaz. Las escenas de destino (Game.tscn,
## Settings.tscn) se conectarán cuando existan; mientras tanto se avisa
## por consola para poder probar la interfaz sin que el proyecto falle.

const INTRO_SCENE_PATH := "res://scenes/BusArrival.tscn"
const GAME_SCENE_PATH := "res://scenes/Game.tscn"
const SETTINGS_SCENE_PATH := "res://scenes/Settings.tscn"

@onready var start_button: Button = $ButtonContainer/StartButton
@onready var settings_button: Button = $ButtonContainer/SettingsButton
@onready var quit_button: Button = $ButtonContainer/QuitButton


func _ready() -> void:
	start_button.pressed.connect(_on_start_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	start_button.grab_focus()


func _on_start_pressed() -> void:
	if ResourceLoader.exists(INTRO_SCENE_PATH):
		get_tree().change_scene_to_file(INTRO_SCENE_PATH)
	elif ResourceLoader.exists(GAME_SCENE_PATH):
		get_tree().change_scene_to_file(GAME_SCENE_PATH)
	else:
		print("[MainMenu] 'Iniciar Turno' presionado (ninguna escena de destino existe aún)")


func _on_settings_pressed() -> void:
	if ResourceLoader.exists(SETTINGS_SCENE_PATH):
		get_tree().change_scene_to_file(SETTINGS_SCENE_PATH)
	else:
		print("[MainMenu] 'Ajustes' presionado (Settings.tscn aún no existe)")


func _on_quit_pressed() -> void:
	get_tree().quit()
