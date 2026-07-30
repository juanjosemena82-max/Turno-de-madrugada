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
			# Turno de NOCHE: Cali -> Vijes. Todos vuelven a casa.
			return {
				"novedad": {},
				"stops": [
					[
						PassengerData.get_student(decisions, "cali_vijes"),
						PassengerData.get_worker(decisions, "cali_vijes"),
						PassengerData.get_hiding_lady(decisions, "cali_vijes"),
					],
				],
			}
		2:
			# Turno de MADRUGADA: Vijes -> Cali. Todos van a sus cosas.
			return {
				"novedad": {
					"news": "La empresa de transporte ha decidido habilitar nuevos puntos de parada en la ruta, para poder atender a más pasajeros.",
					"mechanics": "Desde ahora el turno tiene varias paradas. Después de atender a los pasajeros de una, el bus sigue hasta la siguiente.",
				},
				"stops": [
					[
						PassengerData.get_student(decisions, "vijes_cali"),
						PassengerData.get_worker(decisions, "vijes_cali"),
					],
					[
						PassengerData.get_carla_contreras(decisions, "vijes_cali"),
						PassengerData.get_patricia_lozano(decisions, "vijes_cali"),
					],
				],
			}
		_:
			# Turnos sin contenido propio todavía: se repite el nivel
			# 2 como relleno temporal, mientras se agregan más días.
			return get_level(2, decisions)
