extends Node

## Controls (Autoload / Singleton)
## Maneja qué tecla está asignada a cada acción del juego (dejar
## subir, no dejar subir, preguntar), permite cambiarlas desde
## Ajustes o Pausa, y las recuerda entre partidas (independiente del
## guardado de la partida en sí).
##
## IMPORTANTE: este script debe registrarse como Autoload en
## Proyecto > Configuración del Proyecto > pestaña "Autoload",
## con el nombre "Controls" apuntando a este archivo.

const CONFIG_PATH := "user://controls.cfg"

## Las acciones remapeables del juego: nombre interno -> texto para
## mostrar en pantalla + tecla por defecto.
const ACTIONS := {
	"board_passenger": {"label": "Dejar subir", "default": KEY_A},
	"deny_passenger": {"label": "No dejar subir", "default": KEY_D},
	"ask_question": {"label": "Preguntar", "default": KEY_S},
}


func _ready() -> void:
	_load_bindings()


func _load_bindings() -> void:
	var config := ConfigFile.new()
	var err := config.load(CONFIG_PATH)

	for action_name in ACTIONS.keys():
		var keycode: int = ACTIONS[action_name]["default"]
		if err == OK and config.has_section_key("controls", action_name):
			keycode = int(config.get_value("controls", action_name))
		_apply_binding(action_name, keycode)


func _apply_binding(action_name: String, keycode: int) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)

	InputMap.action_erase_events(action_name)

	var event := InputEventKey.new()
	event.physical_keycode = keycode
	InputMap.action_add_event(action_name, event)


func rebind(action_name: String, keycode: int) -> void:
	## Reasigna una acción a una tecla nueva y lo guarda de inmediato,
	## para que se recuerde aunque cierres el juego.
	_apply_binding(action_name, keycode)

	var config := ConfigFile.new()
	config.load(CONFIG_PATH)
	config.set_value("controls", action_name, keycode)
	config.save(CONFIG_PATH)


func get_keycode(action_name: String) -> int:
	var events := InputMap.action_get_events(action_name)
	if events.is_empty():
		return ACTIONS.get(action_name, {}).get("default", 0)
	var event: InputEventKey = events[0]
	return event.physical_keycode


func get_key_label(action_name: String) -> String:
	return OS.get_keycode_string(get_keycode(action_name))


func get_action_label(action_name: String) -> String:
	return ACTIONS.get(action_name, {}).get("label", action_name)


func get_action_names() -> Array:
	return ACTIONS.keys()
