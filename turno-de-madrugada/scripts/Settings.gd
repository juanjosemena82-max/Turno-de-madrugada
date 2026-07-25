extends Control

## Pantalla de Ajustes: pestaña "General" (volumen y pantalla completa)
## y pestaña "Controles" (referencia de las teclas del juego).
## Se llega aquí desde el ícono ⚙ del menú principal, y "Volver"
## regresa directo al menú principal.

const MAIN_MENU_PATH := "res://scenes/MainMenu.tscn"

@onready var volume_slider: HSlider = $TabContainer/General/VolumeSlider
@onready var fullscreen_checkbox: CheckBox = $TabContainer/General/FullscreenCheckBox
@onready var back_button: Button = $BackButton


func _ready() -> void:
	var master_bus := AudioServer.get_bus_index("Master")
	volume_slider.value = db_to_linear(AudioServer.get_bus_volume_db(master_bus))
	volume_slider.value_changed.connect(_on_volume_changed)

	fullscreen_checkbox.button_pressed = (
		DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	)
	fullscreen_checkbox.toggled.connect(_on_fullscreen_toggled)

	back_button.pressed.connect(_on_back_pressed)
	back_button.grab_focus()


func _on_volume_changed(value: float) -> void:
	var master_bus := AudioServer.get_bus_index("Master")
	AudioServer.set_bus_volume_db(master_bus, linear_to_db(value))


func _on_fullscreen_toggled(pressed: bool) -> void:
	if pressed:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file(MAIN_MENU_PATH)
