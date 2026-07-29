extends Control

## Menú principal de "Turno de Madrugada".
## - Jugar: si ya existe una partida guardada la retoma (cargando el
##   historial de turnos); si no existe ninguna, empieza una nueva
##   desde el día 1. En ambos casos lleva a la pantalla de Turnos.
## - El ícono de ajustes vive aparte, en la esquina superior derecha.

const TURNS_SCENE_PATH := "res://scenes/TurnsScreen.tscn"
const SETTINGS_SCENE_PATH := "res://scenes/Settings.tscn"

@onready var start_button: Button = $ButtonContainer/StartButton
@onready var quit_button: Button = $ButtonContainer/QuitButton
@onready var settings_icon_button: Button = $SettingsIconButton


func _ready() -> void:
	start_button.pressed.connect(_on_start_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	settings_icon_button.pressed.connect(_on_settings_pressed)

	start_button.grab_focus()


func _on_start_pressed() -> void:
	# Ya no hay botón "Continuar" separado: "Jugar" retoma la partida
	# guardada si existe, o arranca una nueva si no.
	if SaveManager.has_save():
		SaveManager.load_game()
	else:
		SaveManager.start_new_game()

	_go_to_turns_screen()


func _go_to_turns_screen() -> void:
	if ResourceLoader.exists(TURNS_SCENE_PATH):
		get_tree().change_scene_to_file(TURNS_SCENE_PATH)
	else:
		print("[MainMenu] TurnsScreen.tscn aún no existe")


func _on_settings_pressed() -> void:
	if ResourceLoader.exists(SETTINGS_SCENE_PATH):
		get_tree().change_scene_to_file(SETTINGS_SCENE_PATH)
	else:
		print("[MainMenu] 'Ajustes' presionado (Settings.tscn aún no existe)")


func _on_quit_pressed() -> void:
	get_tree().quit()
