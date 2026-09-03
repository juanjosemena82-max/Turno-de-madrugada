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
##   "category"   -> categoría del pasajero (A = común, B = con
##                    secreto, C = peligroso...). Afecta cuánto sube
##                    o baja la Confianza del pueblo y los Ahorros
##                    con cada decisión.
##   "name"       -> nombre mostrado en la barra
##   "portrait"   -> ruta a su retrato
##   "lines"      -> diálogo del pasajero, en orden
##   "questions"  -> lo que pregunta el cobrador para sacar cada
##                   línea. questions[0] va vacío (la primera línea
##                   la dice el pasajero solo, sin que se le pregunte
##                   nada). questions[i] es la pregunta que provoca
##                   lines[i], para i >= 1.
##   "always_ask" -> si el botón "Preguntar" nunca se debe ocultar
##   "complaint_if_denied" -> (opcional) si el jugador decide "vete"
##                    con este pasajero sin una razón de seguridad
##                    válida, se registra una queja formal (para uso
##                    futuro en la historia) con este texto como
##                    motivo interno.
##   "denial_reaction" -> (opcional) el mensaje corto que aparece en
##                    pantalla (arriba a la izquierda) si se rechaza
##                    a este pasajero — puede ser su propia reacción
##                    o el comentario de otro pasajero que va en el
##                    bus. Personajes sin este campo no muestran nada.

static func stuard_passed_parcial(decision_log: Dictionary) -> bool:
	## Se decide con las primeras 4 decisiones que se tomaron con
	## Stuard (turnos 1 a 4, antes del parcial): si hubo 0 o 1 veces
	## que no lo dejaron subir, pasa; si hubo 2 o más, pierde. Se usa
	## tanto para su propio diálogo del turno 5 como para la Novedad
	## del turno 6, así que siempre da el mismo resultado en ambos.
	var log: Array = decision_log.get("stuard_contreras", [])
	var relevant: Array = log.slice(0, min(4, log.size()))
	var vete_count: int = 0
	for r in relevant:
		if r == "vete":
			vete_count += 1
	return vete_count <= 1


static func get_student(decisions: Dictionary = {}, route: String = "vijes_cali", decision_log: Dictionary = {}) -> Dictionary:
	var last_result: String = decisions.get("stuard_contreras", "")
	var log: Array = decision_log.get("stuard_contreras", [])
	var lines: Array
	var questions: Array

	if route == "cali_vijes":
		if log.size() < 2:
			# Turno 1, de noche: vuelve a Vijes a estudiar para el
			# parcial de mañana. Todavía no ha pasado nada.
			lines = [
				"Uy, menos mal alcancé este bus.",
				"Tengo que estudiar para un parcial mañana.",
				"Vivo en Vijes, ya casi llego a descansar.",
			]
			questions = [
				"",
				"¿Y usted para dónde va tan tarde?",
				"¿Vive por aquí cerca?",
			]
		elif log.size() < 4:
			# Turno 3, de noche: su diálogo depende de las últimas
			# dos decisiones (turno 1 y turno 2 con él), no solo la
			# más reciente.
			var turn1_result: String = log[-2]
			var turn2_result: String = log[-1]

			if turn1_result == "vete" and turn2_result == "pasar":
				lines = [
					"Uf, esta vez sí alcancé a llegar al examen, por poquito.",
					"Solo un milagro me ayudará a pasar el parcial, no estudié lo suficiente.",
					"Bueno, ya qué. A esperar la nota.",
				]
				questions = ["", "¿Cómo le fue con el parcial?", "¿Está muy preocupado?"]
			elif turn1_result == "pasar" and turn2_result == "vete":
				lines = [
					"Casi no me dejan hacer el parcial, gracias a que no me dejaron subir la otra vez.",
					"Al final llegué corriendo, alcancé a entrar por un pelo.",
					"Menos mal había estudiado bien esa noche, si no, no la cuento.",
				]
				questions = ["", "¿Qué pasó con el parcial?", "¿Alcanzó a presentarlo?"]
			elif turn1_result == "pasar" and turn2_result == "pasar":
				lines = [
					"Estoy seguro que pasaré el parcial, ya siento la graduación.",
					"Gracias a usted pude llegar bien las dos veces.",
					"Ya me queda poco para terminar la carrera.",
				]
				questions = ["", "¿Tan seguro está?", "¿Le falta mucho para graduarse?"]
			else:
				# vete + vete: las dos veces le fue mal.
				lines = [
					"Ya ni sé cómo voy a presentar ese parcial, todo se me ha complicado.",
					"Entre no dejarme subir esa vez y esta, perdí más de lo que pensaba.",
					"A ver qué invento para no perder el semestre.",
				]
				questions = ["", "¿Qué le pasó esta vez?", "¿Va a poder recuperarse?"]
		else:
			# Turno 5, de noche: se sabe el resultado del parcial. Se
			# decide según el historial completo con él (ver
			# stuard_passed_parcial). Este momento también define lo
			# que se sabrá en la Novedad del turno 6.
			if stuard_passed_parcial(decision_log):
				lines = [
					"¡¡¡He pasado el parcial!!! Me gradúo, muchas gracias por transportarme todo este tiempo.",
					"No lo hubiera logrado sin usted, de verdad.",
					"Voy a celebrar con mi familia en Vijes.",
				]
				questions = ["", "¿Cómo se siente?", "¿Qué va a hacer ahora?"]
			else:
				lines = [
					"No pasé el parcial... ya perdí la esperanza de sacar la carrera adelante.",
					"Ya no sé qué hacer con mi vida.",
					"Disculpe, no tengo ánimo de hablar más.",
				]
				questions = ["", "¿Qué va a hacer ahora?", "¿Está bien?"]
	else:
		# Turno de madrugada: va camino al examen. La primera vez
		# (turno 2) el diálogo depende de si lo dejaron subir la
		# noche anterior. La segunda vez (turno 4) ya está en la
		# recta final antes del parcial y solo piensa en eso.
		if log.size() < 2:
			if last_result == "vete":
				lines = [
					"Anoche no me dejaron subir... casi no pude estudiar.",
					"Espero que me vaya bien de todas formas.",
					"Voy para la Universidad del Valle, tengo el parcial temprano.",
				]
				questions = [
					"",
					"¿Qué le pasó anoche?",
					"¿Para dónde va?",
				]
			else:
				lines = [
					"Espero pasar el examen, estudié mucho anoche.",
					"Voy para la Universidad del Valle, tengo el parcial temprano.",
					"Gracias por dejarme subir ayer, alcancé a estudiar tranquilo.",
				]
				questions = [
					"",
					"¿Para dónde va tan temprano?",
					"¿Y cómo le fue anoche?",
				]
		else:
			# Turno 4: susurrando, muy nervioso.
			lines = [
				"(susurrando) Por favor, por favor que pase el parcial...",
				"Si no lo paso, me muero.",
				"Perdón, es que estoy muy nervioso. Voy para la Universidad del Valle.",
			]
			questions = [
				"",
				"¿Está bien? Lo veo susurrando algo.",
				"¿Para dónde va?",
			]

	return {
		"id": "stuard_contreras",
		"category": "A",
		"name": "Stuard Contreras",
		"portrait": "res://assents/characters/A_10.png",
		"lines": lines,
		"questions": questions,
		"always_ask": false,
	}


static func get_worker(decisions: Dictionary = {}, route: String = "vijes_cali") -> Dictionary:
	## Eugenio es un personaje recurrente: cómo lo trates turno a
	## turno (dejarlo pasar y preguntarle algo, o no dejarlo pasar,
	## o dejarlo pasar sin nunca preguntarle nada) va formando una
	## relación de Amistad que cambia su forma de hablarte con el
	## tiempo (SaveManager.get_affinity_label).
	var affinity: String = SaveManager.get_affinity_label("eugenio_escobar")
	var lines: Array
	var questions: Array = ["", "¿Usted para dónde va?"]

	if route == "cali_vijes":
		# Turno de noche: Eugenio vuelve a casa después de trabajar.
		var variants: Array
		if affinity == "amigo":
			variants = [
				"¡Quiúbo, socio! Menos mal es usted el de hoy.",
				"Buena esa, ya nos conocemos bien. ¿Cómo le ha ido?",
				"Con usted el viaje se hace más corto, de verdad.",
			]
		elif affinity == "le_caes_mal":
			variants = [
				"Buenas.",
				"...",
				"Ya sabe cómo es esto, sin más rodeos.",
			]
		else:
			variants = [
				"Uy, qué día tan largo en la bodega.",
				"Ya quiero llegar a Vijes a descansar.",
				"El jefe anda de mal genio esta semana.",
				"Mañana toca madrugar otra vez, qué pereza.",
			]
		lines = [variants[randi() % variants.size()], "Vivo en Vijes, ya casi llegamos."]
	else:
		# Turno de madrugada: va camino al trabajo en Yumbo.
		var variants: Array
		if affinity == "amigo":
			variants = [
				"¡Buenas! Con este frío, se agradece ver una cara conocida.",
				"Otra vez usted por acá, qué bueno.",
				"Ya casi ni necesito decir para dónde voy, ¿cierto?",
			]
		elif affinity == "le_caes_mal":
			variants = [
				"Buenas.",
				"Turno de las cinco, lo de siempre.",
				"...",
			]
		else:
			variants = [
				"Turno de las cinco, como siempre.",
				"Hoy amanecí más cansado que de costumbre.",
				"Ya me sé de memoria cada bache de esta vía.",
				"Uy, hoy sí hizo frío para variar.",
			]
		lines = [variants[randi() % variants.size()], "Trabajo en una bodega en Yumbo, me quedo por ahí."]
		questions = ["", "¿Para dónde se dirige?"]

	return {
		"id": "eugenio_escobar",
		"category": "A",
		"name": "Eugenio Escobar",
		"portrait": "res://assents/characters/A_02.png",
		"lines": lines,
		"questions": questions,
		"always_ask": false,
	}


static func get_hiding_lady(decisions: Dictionary = {}, route: String = "cali_vijes") -> Dictionary:
	return {
		"id": "gloria_ines_cardona",
		"category": "B",
		"name": "Gloria Inés Cardona",
		"portrait": "res://assents/characters/A_12.png",
		"lines": [
			"Buenas noches... voy a visitar a mi hermana en Vijes, nada más.",
			"No, no llevo nada importante conmigo, solo cosas mías.",
			"¿Por qué pregunta tanto? Ya le dije lo que necesitaba saber.",
			"Mire, ya se lo dije. No tengo nada más que contarle.",
		],
		"questions": [
			"",
			"¿Lleva algo con usted?",
			"¿Segura que no hay nada más que contar?",
			"¿De verdad no tiene nada más que decirme?",
		],
		"always_ask": true,
	}


static func get_carla_contreras(decisions: Dictionary = {}, route: String = "vijes_cali") -> Dictionary:
	var last_result: String = decisions.get("carla_contreras", "")
	var lines: Array
	var questions: Array

	if route == "cali_vijes":
		# Turno 7: ya saliendo de su trabajo, de vuelta a Vijes.
		lines = [
			"Uy, por fin salgo del trabajo.",
			"La oficina no da tregua, pero ya me estoy acostumbrando.",
			"Vuelvo a Vijes a descansar.",
		]
		questions = ["", "¿Cómo le va en el trabajo?", "¿Se queda en Vijes?"]
	elif last_result == "":
		# Turno 2: primera vez, va con afán a una cita en Cali.
		lines = [
			"¡Al fin pasa un bus! Voy hasta la terminal de Cali.",
			"Tengo una cita que no puedo perder, ojalá no se demore mucho.",
			"Sí, tengo bastante afán, pero gracias por preguntar.",
		]
		questions = ["", "¿Para dónde va con tanto afán?", "¿Tiene afán?"]
	elif last_result == "pasar":
		# Turno 6: le fue bien, ahora trabaja en Cali.
		lines = [
			"Me fue bien en la cita, ahora voy a Cali a trabajar en la oficina, soy contadora.",
			"Gracias otra vez por dejarme llegar a tiempo esa vez.",
			"Hoy sí que no tengo afán, jaja.",
		]
		questions = ["", "¿Cómo le fue?", "¿A qué se dedica?"]
	else:
		# Turno 6: perdió la cita por no haberla dejado pasar antes.
		lines = [
			"Perdí la cita, no la alcancé, me tocó esperar otro bus y llegué tarde.",
			"Ahora me tocará aguantar hasta que me den otra cita. ¿Cuánto tardará eso?",
			"Voy para Cali otra vez, a ver si esta vez sí tengo suerte.",
		]
		questions = ["", "¿Qué pasó con la cita?", "¿Para dónde va ahora?"]

	return {
		"id": "carla_contreras",
		"category": "A",
		"name": "Carla Contreras",
		"portrait": "res://assents/characters/A_11.png",
		"lines": lines,
		"questions": questions,
		"always_ask": false,
	}


static func get_patricia_lozano(decisions: Dictionary = {}, route: String = "vijes_cali") -> Dictionary:
	return {
		"id": "patricia_lozano",
		"category": "A",
		"name": "Patricia Lozano",
		"portrait": "res://assents/characters/A_07.png",
		"lines": [
			"A esta hora siempre espero el bus, no falla.",
			"Sí, todos los días a esta misma hora, ya me conocen por aquí.",
			"Yo me quedo por Sameco, avíseme cuando lleguemos por ahí.",
		],
		"questions": [
			"",
			"¿Viaja seguido a esta hora?",
			"¿Para dónde se baja?",
		],
		"always_ask": false,
	}


static func get_mercedes_patino(decisions: Dictionary = {}, route: String = "cali_vijes") -> Dictionary:
	## A-01. Señora de 74 años, lleva toda la vida en esta ruta.
	## De noche (cali_vijes) va a Vijes a visitar a su nieta; de
	## madrugada (vijes_cali) ya se está devolviendo para Cali,
	## porque terminó su visita.
	var lines: Array
	var questions: Array

	if route == "cali_vijes":
		lines = [
			"Buenas, mijo... voy pa' Vijes, donde mi nieta.",
			"Uy, este bus ha cambiao tanto... yo lo cojo desde que tenía veinte años.",
			"Ya no ando tan rápido, discúlpeme si me demoro pa' subir.",
		]
		questions = [
			"",
			"¿Viaja seguido por esta ruta?",
			"¿Necesita ayuda para subir?",
		]
	else:
		lines = [
			"Ya me toca volver pa' Cali, mijo. Se acabó la visita.",
			"Estuve donde mi nieta esta semana, ya extrañaba mi casa.",
			"Espero volver pronto, la niña ya casi ni me deja ir.",
		]
		questions = [
			"",
			"¿Qué tal la visita?",
			"¿Vuelve pronto por acá?",
		]

	return {
		"id": "mercedes_patino",
		"category": "A",
		"name": "Doña Mercedes Patiño",
		"portrait": "res://assents/characters/A_01.png",
		"lines": lines,
		"questions": questions,
		"always_ask": false,
	}


static func get_mariela_aguirre(decisions: Dictionary = {}, route: String = "cali_vijes") -> Dictionary:
	## A-03. Enfermera. Vive en Vijes. De noche (cali_vijes) vuelve a
	## casa después de un turno largo; de madrugada (vijes_cali) va
	## camino al hospital para empezar su turno.
	var lines: Array
	var questions: Array

	if route == "cali_vijes":
		lines = [
			"Buenas noches, vengo saliendo de un turno larguísimo en el hospital.",
			"Trabajo en urgencias, así que ya nada me sorprende a estas horas.",
			"Voy para Vijes, a descansar antes de volver mañana.",
		]
		questions = [
			"",
			"¿De dónde viene tan tarde?",
			"¿Es duro el trabajo en urgencias?",
		]
	else:
		lines = [
			"Buenas, voy para el hospital, me toca abrir turno temprano.",
			"Trabajo en urgencias, así que hoy quién sabe qué me espera.",
			"Vivo aquí en Vijes, madrugo casi todos los días para el trabajo.",
		]
		questions = [
			"",
			"¿Para dónde va tan temprano?",
			"¿Vive por acá?",
		]

	return {
		"id": "mariela_aguirre",
		"category": "A",
		"name": "Mariela Aguirre",
		"portrait": "res://assents/characters/A_03.png",
		"lines": lines,
		"questions": questions,
		"always_ask": false,
	}


static func get_bank_robber(decisions: Dictionary = {}, route: String = "cali_vijes") -> Dictionary:
	## C-01. Wilson Andrés Pedraza, el sospechoso del asalto al banco
	## agrario. Intenta sobornar al cobrador: "pasar" = aceptar el
	## dinero y dejarlo subir, "vete" = rechazarlo y no dejarlo subir.
	return {
		"id": "c01_asaltante",
		"category": "C",
		"name": "Wilson Andrés Pedraza",
		"portrait": "res://assents/characters/C_01.png",
		"lines": [
			"Buenas... solo quiero llegar a Vijes, nada más.",
			"Mire, tengo dos fajos de billetes aquí. Son suyos si me deja tranquilo.",
			"¿Qué dice? Nadie tiene que enterarse de esto.",
		],
		"questions": [
			"",
			"¿Por qué anda tan nervioso?",
			"¿Me está ofreciendo dinero?",
		],
		"always_ask": true,
	}


static func get_hernando_gomez(decisions: Dictionary = {}, route: String = "vijes_cali") -> Dictionary:
	## B-01. Hernando Gómez Salcedo. Vendedor informal de toda la
	## vida (ropa, tecnología, lo que se dé). Vuelve a Cali después
	## de vender mercancía en el pueblo.
	##
	## Lo que dice: que el maletín está vacío, que solo vino a
	## visitar a un familiar. La verdad: el maletín tiene doble
	## fondo con efectivo de mercancía de contrabando menor — no es
	## peligroso, pero sí ilegal (fuera de la jurisdicción de la
	## empresa de buses, así que no es motivo válido para negarle el
	## viaje).
	##
	## Decisión correcta: dejarlo subir. Negarle el paso "porque se
	## ve sospechoso", sin una razón de seguridad real, genera una
	## queja formal (ver "complaint_if_denied").
	return {
		"id": "hernando_gomez_salcedo",
		"category": "B",
		"name": "Hernando Gómez Salcedo",
		"portrait": "res://assents/characters/B_01.png",
		"lines": [
			"Buenas... vengo de visitar a un familiar por acá, ya de vuelta pa' Cali.",
			"No, no llevo nada, el maletín va vacío. Vendí ropa por el pueblo y aproveché a dejarle unas cositas a mi familiar.",
			"Es que se me dañó el carro, por eso me tocó en bus.",
			"Ya le conté todo, no tengo más que decir.",
		],
		"questions": [
			"",
			"¿Qué lleva en el maletín?",
			"¿Y por qué no vino en carro, si carga mercancía?",
			"¿Seguro que no hay nada más?",
		],
		"always_ask": true,
		"complaint_if_denied": "Rechazo por apariencia, sin causa específica de seguridad.",
		"denial_reaction": "Una señora que va más atrás murmura: \"Pobre hombre, debieron dejarlo pasar...\"",
	}


static func get_rodrigo_andrade(decisions: Dictionary = {}) -> Dictionary:
	## B-03. Dice ir "a ver a unos parceros". La verdad: va a una
	## reunión con su proveedor de chance (paga la semana, recoge
	## talonarios nuevos). Nada peligroso, solo ilegal a medias.
	return {
		"id": "rodrigo_andrade",
		"category": "B",
		"name": "Rodrigo Andrade Llanos",
		"portrait": "res://assents/characters/B_03.png",
		"lines": [
			"Buenas, voy pa' Cali a ver a unos parceros.",
			"Nada, cositas mías, un negocio pequeño que tengo por allá.",
			"Es que hoy no tenía quién me llevara, por eso el bus.",
		],
		"questions": [
			"",
			"¿Qué lo lleva a Cali tan tarde?",
			"¿Y esos tenis tan buenos, para un negocio tan pequeño?",
		],
		"always_ask": true,
	}


static func get_esteban_cordoba(decisions: Dictionary = {}) -> Dictionary:
	## A-08. Niño que viaja solo con una carta de su mamá para su
	## papá en Vijes. Trae "requires_verification": true — si se le
	## deja subir sin haber usado "Preguntar" para leer la carta, la
	## empresa registra un error aunque el niño esté perfectamente
	## bien (ver Game.gd).
	return {
		"id": "esteban_cordoba",
		"category": "A",
		"name": "Esteban Córdoba",
		"portrait": "res://assents/characters/A_08.png",
		"lines": [
			"Hola señor... ¿me deja subir? Voy donde mi papá, en Vijes.",
			"(la carta dice) \"A quien corresponda: mi hijo Esteban va a visitar a su padre en Vijes. No es fácil para mí dejarlo viajar solo, pero es importante que lo vea. Le pido de favor que lo cuide durante el trayecto y se asegure de que llegue bien. Gracias por su comprensión y su ayuda. Atentamente, su madre.\"",
			"Mi mamá dice que mi papá me está esperando allá, en la casa de siempre.",
		],
		"questions": [
			"",
			"¿Traes algo que demuestre que puedes viajar solo?",
			"¿Tu papá sabe que vienes?",
		],
		"always_ask": false,
		"requires_verification": true,
	}


static func get_esteban_farewell() -> Dictionary:
	## Última parada del turno 5, ya en Vijes: escena de solo texto,
	## sin decisión que tomar (scripted: true), donde Esteban se
	## despide antes de bajarse.
	return {
		"scripted": true,
		"name": "Esteban Córdoba",
		"portrait": "res://assents/characters/A_08.png",
		"lines": [
			"Muchas gracias por traerme, señor.",
			"Espero que mi papá me trate bien esta vez...",
		],
	}


static func get_rosalba_mosquera(decisions: Dictionary = {}) -> Dictionary:
	## A-09. Vendedora de frutas, un poco borracha (aguardiente
	## "para el frío"). Si se le deja pasar molesta a los demás
	## pasajeros y genera una queja ("complaint_if_allowed"). Si no
	## se le deja pasar, amenaza con reportar a la empresa, pero no
	## lo hace (solo queda como diálogo, sin consecuencia real).
	return {
		"id": "rosalba_mosquera",
		"category": "A",
		"name": "Rosalba Mosquera",
		"portrait": "res://assents/characters/A_09.png",
		"lines": [
			"(con aliento a aguardiente) Buenas, mijo, vendo frutas por el pueblo.",
			"Es pa'l frío, no más, un traguito de vez en cuando no hace daño.",
			"¿Y usted qué me mira tanto? ¡Ya le dije que es pa'l frío! Y si no me deja subir, esto se lo cuento a la empresa, ¡ya verá!",
		],
		"questions": [
			"",
			"¿Y esa botella?",
			"¿Está en condiciones de viajar?",
		],
		"always_ask": true,
		"complaint_if_allowed": "Un pasajero se queja: \"Esa señora no paró de molestar en todo el viaje, debieron bajarla.\"",
	}


static func get_pacho_mecanico(decisions: Dictionary = {}, route: String = "vijes_cali") -> Dictionary:
	## A-06. Mecánico de Vijes que va a hacer un trabajo a Cali.
	var lines: Array
	var questions: Array

	if route == "vijes_cali":
		lines = [
			"Buenas, voy pa' Cali, tengo un trabajo por allá.",
			"Soy mecánico, me llamaron para arreglar un carro complicado.",
			"Ojalá no me quede muy tarde, mañana toca taller aquí en Vijes.",
		]
		questions = ["", "¿Qué lo lleva a Cali?", "¿Es cliente de confianza?"]
	else:
		lines = [
			"Es un trabajo difícil el de mi cliente, mañana tendré que volver.",
			"El carro tenía más daños de los que pensaba.",
			"Menos mal ya casi llegamos a Vijes, estoy agotado.",
		]
		questions = ["", "¿Cómo le fue con el trabajo?", "¿Va a volver mañana?"]

	return {
		"id": "pacho_mecanico",
		"category": "A",
		"name": "Pacho",
		"portrait": "res://assents/characters/A_06.png",
		"lines": lines,
		"questions": questions,
		"always_ask": false,
	}


static func get_bernardo_silva(decisions: Dictionary = {}) -> Dictionary:
	## C-02. Bernardo Silva Mora. Dice ser comerciante de Palmira, va
	## a Vijes "a cerrar un negocio con un proveedor". La verdad: se
	## esconde de un grupo criminal al que le debe dinero. Bernardo
	## en sí no es el peligro — lo son quienes lo buscan.
	##
	## No se le pone "category" (queda vacía a propósito): las
	## consecuencias de esta decisión no pasan por la Confianza ni
	## los Ahorros normales, sino por una mecánica de historia aparte
	## que se construirá más adelante (si no lo dejas subir, aparece
	## reportado desaparecido y luego muerto en las noticias; si lo
	## dejas subir, más adelante lo interrogan a usted sobre él).
	return {
		"id": "bernardo_silva",
		"category": "",
		"name": "Bernardo Silva Mora",
		"portrait": "res://assents/characters/C_02.png",
		"lines": [
			"Buenas... voy a Vijes, a cerrar un negocio con un proveedor.",
			"Tengo un local en Palmira, soy comerciante de toda la vida.",
			"Solo quiero llegar tranquilo, se lo pido por favor.",
		],
		"questions": [
			"",
			"¿Qué clase de negocio lo lleva a Vijes tan tarde?",
			"¿Por qué se le nota tan nervioso?",
		],
		"always_ask": true,
	}
