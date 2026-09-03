extends Node
class_name LevelData

## Define el contenido de cada turno/día:
##   "route"   -> "cali_vijes" o "vijes_cali", para saber qué tramo
##                de la ruta (Vijes - Yumbo - Cali) es este turno.
##                Se muestra en la pantalla de Novedad.
##   "novedad" -> Dictionary con "news" y "mechanics". Todo turno
##                debería traer algo aquí, aunque sea solo lore
##                (no hace falta que siempre explique una mecánica
##                nueva). El texto no debe explicar en frío qué
##                botón usar; mejor una frase que sugiera la
##                decisión sin instruir paso a paso.
##   "stops"   -> Array de paradas. Cada parada es un Array de
##                pasajeros (Dictionary, sacados de PassengerData).
##
## Entre cada parada, el juego repite la animación del bus llegando
## antes de mostrar a los pasajeros de la siguiente.

static func get_level(day: int, decisions: Dictionary, decision_log: Dictionary = {}) -> Dictionary:
	match day:
		1:
			# Turno de NOCHE: Cali -> Vijes. Todos vuelven a casa.
			return {
				"route": "cali_vijes",
				"novedad": {
					"news": "Primera noche cubriendo turnos extra en la ruta. Nadie más quiso tomarlos, pero cada peso ayuda para la finca.",
					"mechanics": "",
				},
				"stops": [
					[
						PassengerData.get_student(decisions, "cali_vijes", decision_log),
						PassengerData.get_worker(decisions, "cali_vijes"),
						PassengerData.get_hiding_lady(decisions, "cali_vijes"),
					],
				],
			}
		2:
			# Turno de MADRUGADA: Vijes -> Cali. Todos van a sus cosas.
			return {
				"route": "vijes_cali",
				"novedad": {
					"news": "La empresa de transporte ha decidido habilitar nuevos puntos de parada en la ruta, para poder atender a más pasajeros.",
					"mechanics": "Desde ahora el turno tiene varias paradas. Después de atender a los pasajeros de una, el bus sigue hasta la siguiente.",
				},
				"stops": [
					[
						PassengerData.get_student(decisions, "vijes_cali", decision_log),
						PassengerData.get_worker(decisions, "vijes_cali"),
					],
					[
						PassengerData.get_carla_contreras(decisions, "vijes_cali"),
						PassengerData.get_patricia_lozano(decisions, "vijes_cali"),
					],
				],
			}
		3:
			# Turno de NOCHE: Cali -> Vijes. Aparece la mecánica del
			# soborno con el sospechoso del asalto al banco.
			return {
				"route": "cali_vijes",
				"novedad": {
					"news": "ÚLTIMA HORA: asaltaron el Banco Agrario y se llevaron todo. El sospechoso sigue prófugo y podría estar tratando de salir del pueblo.",
					"mechanics": "En tus manos está la decisión de a quién llevar.",
				},
				"stops": [
					[
						PassengerData.get_student(decisions, "cali_vijes", decision_log),
						PassengerData.get_mercedes_patino(decisions),
						PassengerData.get_mariela_aguirre(decisions),
					],
					[
						PassengerData.get_worker(decisions, "cali_vijes"),
						PassengerData.get_bank_robber(decisions),
					],
				],
			}
		4:
			# Turno de MADRUGADA: Vijes -> Cali. Última recta antes
			# del parcial de Stuard, y aparece Hernando con su
			# maletín de doble fondo.
			return {
				"route": "vijes_cali",
				"novedad": {
					"news": "El gobierno decidió levantar la protección legal sobre el páramo y buena parte de la selva amazónica, permitiendo actividades que antes estaban prohibidas. Ambientalistas y comunidades locales han expresado su rechazo.",
					"mechanics": "",
				},
				"stops": [
					[
						PassengerData.get_worker(decisions, "vijes_cali"),
						PassengerData.get_student(decisions, "vijes_cali", decision_log),
						PassengerData.get_mariela_aguirre(decisions, "vijes_cali"),
					],
					[
						PassengerData.get_hernando_gomez(decisions),
					],
					[],
				],
			}
		5:
			# Turno de NOCHE: Cali -> Vijes. Se sabe el resultado del
			# parcial de Stuard, aparece Rodrigo (chance ilegal) y
			# Esteban con la carta (mecánica de verificar documentos).
			return {
				"route": "cali_vijes",
				"novedad": {
					"news": "Se sigue buscando al presunto ladrón del Banco Agrario. Hasta el momento no hay pistas de su paradero, y las autoridades piden a la comunidad reportar cualquier movimiento sospechoso en la zona.",
					"mechanics": "Ahora puedes recibir papeles y documentos de algunos pasajeros. Léelos bien antes de decidir.",
				},
				"stops": [
					[
						PassengerData.get_student(decisions, "cali_vijes", decision_log),
						PassengerData.get_rodrigo_andrade(decisions),
						PassengerData.get_esteban_cordoba(decisions),
					],
					[
						PassengerData.get_worker(decisions, "cali_vijes"),
						PassengerData.get_rosalba_mosquera(decisions),
					],
					[
						PassengerData.get_esteban_farewell(),
					],
				],
			}
		6:
			# Turno de MADRUGADA: Vijes -> Cali. La Novedad depende de
			# si Stuard pasó o no el parcial (turno 5).
			var novedad_texto: String
			if PassengerData.stuard_passed_parcial(decision_log):
				novedad_texto = "Los estudiantes universitarios ya salen a vacaciones, y quienes terminaron su carrera se preparan para su ceremonia de grado."
			else:
				novedad_texto = "Se encontró el cuerpo de un joven estudiante universitario colgado de un árbol en las afueras del pueblo. La policía investiga los hechos, aunque todo apunta a un presunto suicidio."

			return {
				"route": "vijes_cali",
				"novedad": {
					"news": novedad_texto,
					"mechanics": "",
				},
				"stops": [
					[
						PassengerData.get_worker(decisions, "vijes_cali"),
						PassengerData.get_mariela_aguirre(decisions, "vijes_cali"),
						PassengerData.get_mercedes_patino(decisions, "vijes_cali"),
					],
					[
						PassengerData.get_carla_contreras(decisions, "vijes_cali"),
						PassengerData.get_pacho_mecanico(decisions, "vijes_cali"),
					],
				],
			}
		7:
			# Turno de NOCHE: Cali -> Vijes. Aparece Bernardo, el
			# deudor que se esconde de un grupo criminal.
			return {
				"route": "cali_vijes",
				"novedad": {
					"news": "Los préstamos \"gota a gota\" se han vuelto cada vez más comunes entre los ciudadanos, pero algunos no logran pagarlos y terminan sufriendo las consecuencias. Piden ayuda a las autoridades.",
					"mechanics": "",
				},
				"stops": [
					[
						PassengerData.get_carla_contreras(decisions, "cali_vijes"),
						PassengerData.get_pacho_mecanico(decisions, "cali_vijes"),
					],
					[
						PassengerData.get_bernardo_silva(decisions),
					],
					[
						PassengerData.get_worker(decisions, "cali_vijes"),
						PassengerData.get_mariela_aguirre(decisions, "cali_vijes"),
					],
				],
			}
		_:
			# Turnos sin contenido propio todavía: se repite el nivel
			# 7 como relleno temporal, mientras se agregan más días.
			return get_level(7, decisions, decision_log)
