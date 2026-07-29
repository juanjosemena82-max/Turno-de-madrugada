extends Node
class_name PassengerData

## Catálogo de pasajeros. Cada función recibe el diccionario de
## "decisions" (SaveManager.get_decisions()) para poder variar el
## diálogo según qué pasó con ese personaje en un turno anterior.
##
## Cada pasajero tiene:
##   "id"         -> identificador estable (para recordar decisiones)
##   "name"       -> nombre mostrado en la barra
##   "portrait"   -> ruta a su retrato
##   "lines"      -> diálogo, en orden
##   "always_ask" -> si el botón "Preguntar" nunca se debe ocultar

static func get_student(decisions: Dictionary = {}) -> Dictionary:
	var last_result: String = decisions.get("stuard_contreras", "")
	var lines: Array

	if last_result == "pasar":
		lines = [
			"¡Buenas! Al final sí alcancé a llegar, pasé el examen.",
			"De verdad gracias por dejarme subir la otra vez.",
			"Hoy no tengo tanto afán, jeje.",
		]
	elif last_result == "vete":
		lines = [
			"...la vez pasada no llegué a tiempo. Perdí el examen por eso.",
			"Tuve que hablar con el profesor para poder presentarlo de nuevo.",
			"Esta vez sí necesito llegar, por favor.",
		]
	else:
		lines = [
			"Buenas... ¿este bus va hacia la universidad?",
			"Es que tengo un examen en 20 minutos, por favor no me lo pierda.",
			"Vivo aquí cerca, salgo tarde casi todos los días, jeje.",
			"¿Ya casi puedo subir? De verdad tengo el tiempo justo.",
		]

	return {
		"id": "stuard_contreras",
		"name": "Stuard Contreras",
		"portrait": "res://assents/characters/Stuard Contreras.png",
		"lines": lines,
		"always_ask": false,
	}


static func get_worker(decisions: Dictionary = {}) -> Dictionary:
	return {
		"id": "eugenio_escobar",
		"name": "Eugenio Escobar",
		"portrait": "res://assents/characters/Eugenio Escobar.png",
		"lines": [
			"Turno de las cinco, como siempre.",
			"Trabajo en la fábrica al otro lado del puente.",
			"Llevo diez años tomando este mismo bus, no hay mucho que contar.",
		],
		"always_ask": false,
	}


static func get_hiding_lady(decisions: Dictionary = {}) -> Dictionary:
	return {
		"id": "gloria_ines_cardona",
		"name": "Gloria Inés Cardona",
		"portrait": "res://assents/characters/Gloria ines cardona.png",
		"lines": [
			"Buen día... voy a visitar a mi hermana, nada más.",
			"No, no llevo nada importante conmigo, solo cosas mías.",
			"¿Por qué pregunta tanto? Ya le dije lo que necesitaba saber.",
			"Mire, ya se lo dije. No tengo nada más que contarle.",
		],
		"always_ask": true,
	}


static func get_carla_contreras(decisions: Dictionary = {}) -> Dictionary:
	return {
		"id": "carla_contreras",
		"name": "Carla Contreras",
		"portrait": "res://assents/characters/Carla Contreras.png",
		"lines": [
			"Buenas, ¿este es el bus de siempre?",
			"Voy para el centro, tengo una cita que no puedo perder.",
			"¿Falta mucho para que salga?",
		],
		"always_ask": false,
	}


static func get_patricia_lozano(decisions: Dictionary = {}) -> Dictionary:
	return {
		"id": "patricia_lozano",
		"name": "Patricia Lozano",
		"portrait": "res://assents/characters/Patricia Lozano.png",
		"lines": [
			"A esta hora siempre espero el bus, no falla.",
			"Uy, justo a tiempo hoy.",
			"Ya casi es mi parada de siempre, no se demore mucho.",
		],
		"always_ask": false,
	}
