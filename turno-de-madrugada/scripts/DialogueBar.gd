extends Control

## Barra de diálogo reutilizable para cualquier pasajero.
## Se le pasa la info de un personaje con start_dialogue(), y ella
## se encarga de mostrar el texto y los botones.
##
## Botones (mouse o teclado):
##   - Pasar     -> tecla A -> deja subir al pasajero
##   - Vete      -> tecla D -> no lo deja subir
##   - Preguntar -> tecla S -> pide otra línea de diálogo
##
## Si el personaje ya no tiene más que contar, "Preguntar" se
## oculta solo. Excepción: si always_ask = true en sus datos (como
## la señora que esconde información), el botón nunca se oculta.

signal passenger_resolved(result: String) # "pasar" o "vete"

@onready var portrait: TextureRect = $Panel/Portrait
@onready var name_label: Label = $Panel/NameLabel
@onready var dialogue_text: Label = $Panel/DialogueText
@onready var pass_button: Button = $Panel/ButtonsContainer/PassButton
@onready var deny_button: Button = $Panel/ButtonsContainer/DenyButton
@onready var ask_button: Button = $Panel/ButtonsContainer/AskButton

var _character_data: Dictionary = {}
var _line_index: int = 0


func _ready() -> void:
	pass_button.pressed.connect(_on_pass_pressed)
	deny_button.pressed.connect(_on_deny_pressed)
	ask_button.pressed.connect(_on_ask_pressed)


func start_dialogue(character_data: Dictionary) -> void:
	_character_data = character_data
	_line_index = 0

	name_label.text = character_data.get("name", "")

	var portrait_path: String = character_data.get("portrait", "")
	if portrait_path != "" and ResourceLoader.exists(portrait_path):
		portrait.texture = load(portrait_path)

	_show_current_line()


func _show_current_line() -> void:
	var lines: Array = _character_data.get("lines", [])
	dialogue_text.text = "" if lines.is_empty() else lines[min(_line_index, lines.size() - 1)]
	_update_ask_button_visibility()


func _update_ask_button_visibility() -> void:
	var lines: Array = _character_data.get("lines", [])
	var always_ask: bool = _character_data.get("always_ask", false)
	var has_more_lines: bool = _line_index < lines.size() - 1

	# La señora que esconde información conserva "Preguntar" siempre,
	# sin importar cuántas veces ya se le preguntó.
	ask_button.visible = always_ask or has_more_lines


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return

	match event.keycode:
		KEY_A:
			_on_pass_pressed()
		KEY_D:
			_on_deny_pressed()
		KEY_S:
			if ask_button.visible:
				_on_ask_pressed()


func _on_pass_pressed() -> void:
	passenger_resolved.emit("pasar")


func _on_deny_pressed() -> void:
	passenger_resolved.emit("vete")


func _on_ask_pressed() -> void:
	var lines: Array = _character_data.get("lines", [])
	if _line_index < lines.size() - 1:
		_line_index += 1
	_show_current_line()
