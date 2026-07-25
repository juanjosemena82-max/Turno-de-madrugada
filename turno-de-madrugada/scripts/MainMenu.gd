extends Control

## Menú principal de "Turno de Madrugada".
## - Iniciar Turno: empieza una partida nueva desde el día 1.
## - Continuar: carga la última partida autoguardada (deshabilitado
##   si todavía no existe ninguna).
## - El ícono de ajustes vive aparte, en la esquina superior derecha.

const INTRO_SCENE_PATH := "res://scenes/BusArrival.tscn"
const GAME_SCENE_PATH := "res://scenes/Game.tscn"
const SETTINGS_SCENE_PATH := "res://scenes/Settings.tscn"

@onready var start_button: Button = $ButtonContainer/StartButton
@onready var continue_button: Button = $ButtonContainer/ContinueButton
@onready var quit_button: Button = $ButtonContainer/QuitButton
@onready var settings_icon_button: Button = $SettingsIconButton


func _ready() -> void:
	start_button.pressed.connect(_on_start_pressed)
	continue_button.pressed.connect(_on_continue_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	settings_icon_button.pressed.connect(_on_settings_pressed)

	# El botón "Continuar" solo se activa si ya existe una partida guardada.
	continue_button.disabled = not SaveManager.has_save()

	start_button.grab_focus()


func _on_start_pressed() -> void:
	SaveManager.start_new_game()
	_go_to_next_scene()


func _on_continue_pressed() -> void:
	if SaveManager.load_game():
		_go_to_next_scene()


func _go_to_next_scene() -> void:
	if ResourceLoader.exists(INTRO_SCENE_PATH):
		get_tree().change_scene_to_file(INTRO_SCENE_PATH)
	elif ResourceLoader.exists(GAME_SCENE_PATH):
		get_tree().change_scene_to_file(GAME_SCENE_PATH)
	else:
		print("[MainMenu] Ninguna escena de destino existe aún")


func _on_settings_pressed() -> void:
	if ResourceLoader.exists(SETTINGS_SCENE_PATH):
		get_tree().change_scene_to_file(SETTINGS_SCENE_PATH)
	else:
		print("[MainMenu] 'Ajustes' presionado (Settings.tscn aún no existe)")


func _on_quit_pressed() -> void:
	get_tree().quit()
