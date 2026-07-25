extends Node2D

## Pantalla principal de juego: la puerta del bus, esperando a que
## aparezcan los pasajeros.

func _ready() -> void:
	pass


func _unhandled_input(event: InputEvent) -> void:
	# TEMPORAL: presiona Enter para simular "fin de turno" y probar
	# que el autoguardado funciona. Cuando exista la lógica real de
	# turnos, esta prueba se reemplaza por la llamada a
	# SaveManager.end_turn() en el momento correcto (ej. cuando el
	# bus se va al final del turno).
	if event.is_action_pressed("ui_accept"):
		SaveManager.end_turn()
		print("[Game] PRUEBA: turno terminado. Día actual: ", SaveManager.current_save["current_day"])
