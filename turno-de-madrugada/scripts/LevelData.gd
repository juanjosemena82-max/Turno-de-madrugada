extends Node
class_name LevelData

## Define el contenido de cada turno/día:
##   "novedad" -> Dictionary con "news" y "mechanics", o un
##                Dictionary vacío {} si ese turno no tiene Novedad.
##   "stops"   -> Array de paradas. Cada parada es un Array de
##                pasajeros (Dictionary, sacados de PassengerData).
##
## Entre cada parada, el juego repite la animación del bus llegando
## antes de mostrar a los pasajeros de la siguiente.

static func get_level(day: int, decisions: Dictionary) -> Dictionary:
	match day:
		1:
			return {
				"novedad": {},
				"stops": [
					[
						PassengerData.get_student(decisions),
						PassengerData.get_worker(decisions),
						PassengerData.get_hiding_lady(decisions),
					],
				],
			}
		2:
			return {
				"novedad": {
					"news": "Anoche se escapó un recluso de la cárcel municipal. Las autoridades piden estar alerta con cualquier pasajero sospechoso.",
					"mechanics": "Desde ahora el turno tiene varias paradas. Presta atención: no todos los pasajeros dicen la verdad sobre a dónde van.",
				},
				"stops": [
					[
						PassengerData.get_student(decisions),
						PassengerData.get_worker(decisions),
					],
					[
						PassengerData.get_carla_contreras(decisions),
						PassengerData.get_patricia_lozano(decisions),
					],
				],
			}
		_:
			# Turnos sin contenido propio todavía: se repite el nivel
			# 2 como relleno temporal, mientras se agregan más días.
			return get_level(2, decisions)
