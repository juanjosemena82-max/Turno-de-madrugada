extends Control

## Pantalla de Ajustes: pestaña "General" (volumen y pantalla completa)
## y pestaña "Controles" (donde se pueden reasignar las teclas del
## juego, generadas dinámicamente a partir de Controls.gd).
## Se llega aquí desde el ícono ⚙ del menú principal, y "Volver"
## regresa directo al menú principal.

const MAIN_MENU_PATH := "res://scenes/MainMenu.tscn"

@onready var volume_slider: HSlider = $TabContainer/General/VolumeSlider
@onready var fullscreen_checkbox: CheckBox = $TabContainer/General/FullscreenCheckBox
@onready var controls_container: VBoxContainer = $TabContainer/Controles
@onready var back_button: Button = $BackButton

var _rebind_action: String = ""
var _rebind_buttons: Dictionary = {}


func _ready() -> void:
	var master_bus := AudioServer.get_bus_index("Master")
	volume_slider.value = db_to_linear(AudioServer.get_bus_volume_db(master_bus))
	volume_slider.value_changed.connect(_on_volume_changed)

	fullscreen_checkbox.button_pressed = (
		DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	)
	fullscreen_checkbox.toggled.connect(_on_fullscreen_toggled)

	_build_controls_rows()

	back_button.pressed.connect(_on_back_pressed)
	back_button.grab_focus()


func _build_controls_rows() -> void:
	## Arma, para cada acción reasignable (Controls.gd), una fila con
	## el nombre de la acción y un botón que muestra la tecla actual.
	## Las inserta justo antes de "CatchRow" (que sigue siendo texto
	## fijo, esa mecánica todavía no existe).
	var catch_row: Node = controls_container.get_node_or_null("CatchRow")
	var insert_index: int = catch_row.get_index() if catch_row != null else controls_container.get_child_count()

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
		controls_container.move_child(row, insert_index)
		insert_index += 1

		_rebind_buttons[action_name] = button


func _on_rebind_button_pressed(action_name: String) -> void:
	_rebind_action = action_name
	_rebind_buttons[action_name].text = "Presiona una tecla..."


func _unhandled_input(event: InputEvent) -> void:
	if _rebind_action == "":
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode != KEY_ESCAPE:
			Controls.rebind(_rebind_action, event.physical_keycode)
		_rebind_buttons[_rebind_action].text = Controls.get_key_label(_rebind_action)
		_rebind_action = ""
		get_viewport().set_input_as_handled()


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
