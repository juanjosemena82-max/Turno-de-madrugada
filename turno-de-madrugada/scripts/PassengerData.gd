extends Node
class_name PassengerData

## Catálogo de pasajeros. Cada función recibe:
##   - "decisions": lo que el jugador decidió con ese personaje en
##     turnos anteriores (SaveManager.get_decisions()).
##   - "route": en qué tramo de la ruta va este turno, porque el bus
##     hace Vijes - Yumbo - Cali de ida y de vuelta, en dos horarios:
##       "cali_vijes"  -> turno de NOCHE, la gente vuelve a casa.
##       "vijes_cali"  -> turno de MADRUGADA, la gente va a sus cosas.
##
## Cada pasajero devuelve:
##   "id"         -> identificador estable (para recordar decisiones)
##   "name"       -> nombre mostrado en la barra
##   "portrait"   -> ruta a su retrato
##   "lines"      -> diálogo, en orden
##   "always_ask" -> si el botón "Preguntar" nunca se debe ocultar

static func get_student(decisions: Dictionary = {}, route: String = "vijes_cali") -> Dictionary:
	var last_result: String = decisions.get("stuard_contreras", "")
	var lines: Array

	if route == "cali_vijes":
		# Turno de noche: vuelve a Vijes a estudiar para el parcial
		# de mañana. Todavía no ha pasado el examen.
		lines = [
			"Uy, menos mal alcancé este bus.",
			"Tengo que estudiar para un parcial mañana.",
			"Vivo en Vijes, ya casi llego a descansar.",
		]
	else:
		# Turno de madrugada: va camino al examen. El diálogo cambia
		# según si lo dejaron subir la noche anterior o no.
		if last_result == "vete":
			lines = [
				"Anoche no me dejaron subir... casi no pude estudiar.",
				"Espero que me vaya bien de todas formas.",
				"Voy para la Universidad del Valle, tengo el parcial temprano.",
			]
		else:
			lines = [
				"Espero pasar el examen, estudié mucho anoche.",
				"Voy para la Universidad del Valle, tengo el parcial temprano.",
				"Gracias por dejarme subir ayer, alcancé a estudiar tranquilo.",
			]

	return {
		"id": "stuard_contreras",
		"name": "Stuard Contreras",
		"portrait": "res://assents/characters/Stuard Contreras.png",
		"lines": lines,
		"always_ask": false,
	}


static func get_worker(decisions: Dictionary = {}, route: String = "vijes_cali") -> Dictionary:
	var lines: Array

	if route == "cali_vijes":
		# Turno de noche: Eugenio vuelve a casa después de trabajar.
		var variants: Array = [
			"Uy, qué día tan largo en la bodega.",
			"Ya quiero llegar a Vijes a descansar.",
			"El jefe anda de mal genio esta semana.",
			"Mañana toca madrugar otra vez, qué pereza.",
		]
		lines = [variants[randi() % variants.size()], "Vivo en Vijes, ya casi llegamos."]
	else:
		# Turno de madrugada: va camino al trabajo en Yumbo.
		var variants: Array = [
			"Turno de las cinco, como siempre.",
			"Hoy amanecí más cansado que de costumbre.",
			"Ya me sé de memoria cada bache de esta vía.",
			"Uy, hoy sí hizo frío para variar.",
		]
		lines = [variants[randi() % variants.size()], "Trabajo en una bodega en Yumbo, me quedo por ahí."]

	return {
		"id": "eugenio_escobar",
		"name": "Eugenio Escobar",
		"portrait": "res://assents/characters/Eugenio Escobar.png",
		"lines": lines,
		"always_ask": false,
	}


static func get_hiding_lady(decisions: Dictionary = {}, route: String = "cali_vijes") -> Dictionary:
	return {
		"id": "gloria_ines_cardona",
		"name": "Gloria Inés Cardona",
		"portrait": "res://assents/characters/Gloria ines cardona.png",
		"lines": [
			"Buenas noches... voy a visitar a mi hermana en Vijes, nada más.",
			"No, no llevo nada importante conmigo, solo cosas mías.",
			"¿Por qué pregunta tanto? Ya le dije lo que necesitaba saber.",
			"Mire, ya se lo dije. No tengo nada más que contarle.",
		],
		"always_ask": true,
	}


static func get_carla_contreras(decisions: Dictionary = {}, route: String = "vijes_cali") -> Dictionary:
	return {
		"id": "carla_contreras",
		"name": "Carla Contreras",
		"portrait": "res://assents/characters/Carla Contreras.png",
		"lines": [
			"¡Al fin pasa un bus! Voy hasta la terminal de Cali.",
			"Tengo una cita que no puedo perder, ojalá no se demore mucho.",
			"¿Falta mucho para que salgamos?",
		],
		"always_ask": false,
	}


static func get_patricia_lozano(decisions: Dictionary = {}, route: String = "vijes_cali") -> Dictionary:
	return {
		"id": "patricia_lozano",
		"name": "Patricia Lozano",
		"portrait": "res://assents/characters/Patricia Lozano.png",
		"lines": [
			"A esta hora siempre espero el bus, no falla.",
			"Uy, justo a tiempo hoy.",
			"Yo me quedo por Sameco, avíseme cuando lleguemos por ahí.",
		],
		"always_ask": false,
	}
