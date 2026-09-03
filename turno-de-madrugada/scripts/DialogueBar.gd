extends Control

## Barra de diálogo reutilizable para cualquier pasajero.
## Se le pasa la info de un personaje con start_dialogue(), y ella
## se encarga de mostrar el texto y los botones.
##
## Botones (mouse o teclado, con las teclas que el jugador tenga
## asignadas en Ajustes/Pausa — por defecto A / D / S):
##   - Pasar     -> deja subir al pasajero
##   - Vete      -> no lo deja subir
##   - Preguntar -> pide otra línea de diálogo
##
## Si el personaje ya no tiene más que contar, "Preguntar" se
## oculta solo. Excepción: si always_ask = true en sus datos (como
## la señora que esconde información), el botón nunca se oculta.
##
## "MODO GUION": si character_data trae "scripted": true, no hay
## decisión que tomar (ni Pasar/Vete/Preguntar) — solo pasa el
## diálogo y un botón de "Continuar". Sirve para escenas que van
## solas, como la despedida final de un personaje.

signal passenger_resolved(result: String, asked_question: bool) # result: "pasar" o "vete"

@onready var portrait: TextureRect = $Panel/Portrait
@onready var name_label: Label = $Panel/NameLabel
@onready var question_label: Label = $Panel/QuestionLabel
@onready var dialogue_text: Label = $Panel/DialogueText
@onready var pass_button: Button = $Panel/ButtonsContainer/PassButton
@onready var deny_button: Button = $Panel/ButtonsContainer/DenyButton
@onready var ask_button: Button = $Panel/ButtonsContainer/AskButton

var _character_data: Dictionary = {}
var _line_index: int = 0
var _asked_question: bool = false
var _is_scripted: bool = false


func _ready() -> void:
	pass_button.pressed.connect(_on_pass_pressed)
	deny_button.pressed.connect(_on_deny_pressed)
	ask_button.pressed.connect(_on_ask_pressed)


func start_dialogue(character_data: Dictionary) -> void:
	_character_data = character_data
	_line_index = 0
	_asked_question = false
	_is_scripted = character_data.get("scripted", false)

	name_label.text = character_data.get("name", "")

	if _is_scripted:
		pass_button.text = "Continuar (%s)" % Controls.get_key_label("board_passenger")
		deny_button.visible = false
		ask_button.visible = false
	else:
		deny_button.visible = true
		# Los textos de los botones muestran la tecla que el jugador
		# tenga asignada en este momento (por si la cambió en Ajustes
		# o Pausa desde la última vez).
		pass_button.text = "Pasar (%s)" % Controls.get_key_label("board_passenger")
		deny_button.text = "Vete (%s)" % Controls.get_key_label("deny_passenger")
		ask_button.text = "Preguntar (%s)" % Controls.get_key_label("ask_question")

	var portrait_path: String = character_data.get("portrait", "")
	if portrait_path != "" and ResourceLoader.exists(portrait_path):
		portrait.texture = load(portrait_path)

	_show_current_line()


func _show_current_line() -> void:
	var lines: Array = _character_data.get("lines", [])
	var questions: Array = _character_data.get("questions", [])

	dialogue_text.text = "" if lines.is_empty() else lines[min(_line_index, lines.size() - 1)]

	# La primera línea es lo que el pasajero dice apenas se le acerca
	# (no hubo pregunta de por medio). Desde la segunda en adelante,
	# sí hubo una pregunta del cobrador que la provocó.
	if _line_index == 0 or questions.is_empty():
		question_label.text = ""
	else:
		var question_index: int = min(_line_index, questions.size() - 1)
		question_label.text = "Tú: " + questions[question_index] if questions[question_index] != "" else ""

	if _is_scripted:
		ask_button.visible = false
	else:
		_update_ask_button_visibility()


func _update_ask_button_visibility() -> void:
	var lines: Array = _character_data.get("lines", [])
	var always_ask: bool = _character_data.get("always_ask", false)
	var has_more_lines: bool = _line_index < lines.size() - 1

	# La señora que esconde información conserva "Preguntar" siempre,
	# sin importar cuántas veces ya se le preguntó.
	ask_button.visible = always_ask or has_more_lines


func _unhandled_input(event: InputEvent) -> void:
	if _is_scripted:
		if event.is_action_pressed("board_passenger"):
			_advance_scripted_line()
		return

	if event.is_action_pressed("board_passenger"):
		_on_pass_pressed()
	elif event.is_action_pressed("deny_passenger"):
		_on_deny_pressed()
	elif event.is_action_pressed("ask_question"):
		if ask_button.visible:
			_on_ask_pressed()


func _advance_scripted_line() -> void:
	var lines: Array = _character_data.get("lines", [])
	if _line_index < lines.size() - 1:
		_line_index += 1
		_show_current_line()
	else:
		passenger_resolved.emit("pasar", false)


func _on_pass_pressed() -> void:
	if _is_scripted:
		_advance_scripted_line()
	else:
		passenger_resolved.emit("pasar", _asked_question)


func _on_deny_pressed() -> void:
	passenger_resolved.emit("vete", _asked_question)


func _on_ask_pressed() -> void:
	_asked_question = true
	var lines: Array = _character_data.get("lines", [])
	if _line_index < lines.size() - 1:
		_line_index += 1
	_show_current_line()
