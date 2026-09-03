extends Control

## Pantalla de Turnos ("Jugar" en el menú principal lleva aquí).
##
## Funciona como el calendario de días de Papers, Please: cada vez
## que se completa un turno (SaveManager.end_turn()), queda registrado
## en el historial y aparece en esta lista. Desde aquí también se
## arranca el turno que sigue.

const INTRO_SCENE_PATH := "res://scenes/BusArrival.tscn"
const GAME_SCENE_PATH := "res://scenes/Game.tscn"
const NOVEDAD_SCENE_PATH := "res://scenes/NovedadScreen.tscn"
const MAIN_MENU_SCENE_PATH := "res://scenes/MainMenu.tscn"

@onready var next_turn_label: Label = $NextTurnLabel
@onready var confianza_label: Label = $ConfianzaLabel
@onready var ahorros_label: Label = $AhorrosLabel
@onready var ahorros_bar: ProgressBar = $AhorrosBar
@onready var history_list: ItemList = $HistoryPanel/HistoryList
@onready var start_turn_button: Button = $StartTurnButton
@onready var back_button: Button = $BackButton
@onready var reset_button: Button = $ResetButton
@onready var reset_confirm_dialog: ConfirmationDialog = $ResetConfirmDialog


func _ready() -> void:
	start_turn_button.pressed.connect(_on_start_turn_pressed)
	back_button.pressed.connect(_on_back_pressed)
	reset_button.pressed.connect(_on_reset_pressed)
	reset_confirm_dialog.confirmed.connect(_on_reset_confirmed)

	_refresh_screen()


func _refresh_screen() -> void:
	var next_day: int = SaveManager.current_save.get("current_day", 1)
	next_turn_label.text = "Próximo turno: %d" % next_day
	start_turn_button.text = "Comenzar Turno %d" % next_day
	confianza_label.text = "Confianza: %s" % SaveManager.get_confianza_label()

	ahorros_label.text = "Ahorros: $%s" % _format_money(SaveManager.get_ahorros())
	ahorros_bar.value = SaveManager.get_ahorros_progress()

	history_list.clear()
	var history: Array = SaveManager.get_turn_history()

	if history.is_empty():
		history_list.add_item("Todavía no has completado ningún turno.")
		history_list.set_item_disabled(0, true)
		return

	# Mostramos el turno más reciente arriba, como una bitácora.
	for i in range(history.size() - 1, -1, -1):
		var entry: Dictionary = history[i]
		var line := "Turno %d — Confianza: %s — %s" % [
			entry.get("day", 0),
			entry.get("confianza_label", "?"),
			entry.get("date", ""),
		]
		history_list.add_item(line)


func _format_money(amount: int) -> String:
	## Le pone separador de miles al número (ej: 1234567 -> 1.234.567).
	var raw := str(amount)
	var formatted := ""
	var count := 0
	for i in range(raw.length() - 1, -1, -1):
		formatted = raw[i] + formatted
		count += 1
		if count % 3 == 0 and i != 0:
			formatted = "." + formatted
	return formatted


func _on_start_turn_pressed() -> void:
	var decisions: Dictionary = SaveManager.get_decisions()
	var decision_log: Dictionary = SaveManager.get_decision_log()
	var day: int = SaveManager.current_save.get("current_day", 1)
	var level: Dictionary = LevelData.get_level(day, decisions, decision_log)
	var novedad: Dictionary = level.get("novedad", {})

	if not novedad.is_empty() and ResourceLoader.exists(NOVEDAD_SCENE_PATH):
		get_tree().change_scene_to_file(NOVEDAD_SCENE_PATH)
	elif ResourceLoader.exists(INTRO_SCENE_PATH):
		get_tree().change_scene_to_file(INTRO_SCENE_PATH)
	elif ResourceLoader.exists(GAME_SCENE_PATH):
		get_tree().change_scene_to_file(GAME_SCENE_PATH)
	else:
		print("[TurnsScreen] Ninguna escena de juego existe aún")


func _on_back_pressed() -> void:
	if ResourceLoader.exists(MAIN_MENU_SCENE_PATH):
		get_tree().change_scene_to_file(MAIN_MENU_SCENE_PATH)


func _on_reset_pressed() -> void:
	reset_confirm_dialog.popup_centered()


func _on_reset_confirmed() -> void:
	SaveManager.delete_save()
	SaveManager.start_new_game()
	_refresh_screen()
