extends CanvasLayer

## Menú de pausa: se activa/desactiva con ESC desde cualquier escena
## donde esté instanciado (por ahora, Game.tscn). Reutiliza los
## mismos controles que la pantalla de Ajustes (volumen, pantalla
## completa, referencia de teclas), más los botones propios de
## pausa (Reanudar / Menú principal).
##
## Al pausar, get_tree().paused = true detiene automáticamente el
## resto del juego (pasajeros, diálogo, etc.) sin necesidad de
## tocar esos scripts, porque su process_mode es el normal
## (INHERIT). Este menú sigue funcionando porque se fuerza su
## process_mode a ALWAYS.

const MAIN_MENU_SCENE_PATH := "res://scenes/MainMenu.tscn"

@onready var root: Control = $Root
@onready var volume_slider: HSlider = $Root/TabContainer/General/VolumeSlider
@onready var fullscreen_checkbox: CheckBox = $Root/TabContainer/General/FullscreenCheckBox
@onready var controls_container: VBoxContainer = $Root/TabContainer/Controles
@onready var resume_button: Button = $Root/ResumeButton
@onready var main_menu_button: Button = $Root/MainMenuButton

var _rebind_action: String = ""
var _rebind_buttons: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	root.process_mode = Node.PROCESS_MODE_ALWAYS

	var master_bus := AudioServer.get_bus_index("Master")
	volume_slider.value = db_to_linear(AudioServer.get_bus_volume_db(master_bus))
	volume_slider.value_changed.connect(_on_volume_changed)

	fullscreen_checkbox.button_pressed = (
		DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	)
	fullscreen_checkbox.toggled.connect(_on_fullscreen_toggled)

	_build_controls_rows()

	resume_button.pressed.connect(_on_resume_pressed)
	main_menu_button.pressed.connect(_on_main_menu_pressed)


func _build_controls_rows() -> void:
	for action_name in Controls.get_action_names():
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		row.alignment = BoxContainer.ALIGNMENT_CENTER

		var label := Label.new()
		label.text = Controls.get_action_label(action_name)
		label.custom_minimum_size = Vector2(150, 0)
		label.add_theme_font_size_override("font_size", 12)
		label.add_theme_color_override("font_color", Color(0.85, 0.85, 0.9))
		row.add_child(label)

		var button := Button.new()
		button.text = Controls.get_key_label(action_name)
		button.custom_minimum_size = Vector2(90, 0)
		button.pressed.connect(_on_rebind_button_pressed.bind(action_name))
		row.add_child(button)

		controls_container.add_child(row)
		_rebind_buttons[action_name] = button


func _on_rebind_button_pressed(action_name: String) -> void:
	_rebind_action = action_name
	_rebind_buttons[action_name].text = "Presiona una tecla..."


func _unhandled_input(event: InputEvent) -> void:
	# Si se está esperando una tecla nueva para reasignar, esa tecla
	# (incluyendo ESC, que cancela sin asignar) se consume aquí y no
	# llega a abrir/cerrar la pausa.
	if _rebind_action != "":
		if event is InputEventKey and event.pressed and not event.echo:
			if event.physical_keycode != KEY_ESCAPE:
				Controls.rebind(_rebind_action, event.physical_keycode)
			_rebind_buttons[_rebind_action].text = Controls.get_key_label(_rebind_action)
			_rebind_action = ""
			get_viewport().set_input_as_handled()
		return

	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		_toggle_pause()
		get_viewport().set_input_as_handled()


func _toggle_pause() -> void:
	root.visible = not root.visible
	get_tree().paused = root.visible


func _on_volume_changed(value: float) -> void:
	var master_bus := AudioServer.get_bus_index("Master")
	AudioServer.set_bus_volume_db(master_bus, linear_to_db(value))


func _on_fullscreen_toggled(pressed: bool) -> void:
	if pressed:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)


func _on_resume_pressed() -> void:
	_toggle_pause()


func _on_main_menu_pressed() -> void:
	get_tree().paused = false
	if ResourceLoader.exists(MAIN_MENU_SCENE_PATH):
		get_tree().change_scene_to_file(MAIN_MENU_SCENE_PATH)
