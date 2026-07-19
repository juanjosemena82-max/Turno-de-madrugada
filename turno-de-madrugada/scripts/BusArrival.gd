extends Node2D

## Animación de intro: el bus llega deslizándose, la pantalla se
## desvanece a negro, y luego se pasa a la escena de juego.
## Todos los valores de abajo se pueden ajustar desde el Inspector
## (selecciona el nodo BusArrival y mira el panel Inspector a la derecha)
## sin tener que tocar el código.

@export_group("Movimiento del bus")
@export var bus_start_x: float = 600.0
@export var bus_end_x: float = 140.0
@export var bus_move_duration: float = 1.4

@export_group("Desvanecido a negro")
@export var fade_duration: float = 0.6
@export var pause_before_fade: float = 0.3

@export_group("Siguiente escena")
@export var next_scene_path: String = "res://scenes/Game.tscn"

@onready var bus: Sprite2D = $Bus
@onready var fade: ColorRect = $FadeOverlay


func _ready() -> void:
	bus.position.x = bus_start_x
	fade.color.a = 0.0

	var tween := create_tween()

	# Paso 1: el bus se desliza hasta su posición de parqueo.
	tween.tween_property(bus, "position:x", bus_end_x, bus_move_duration)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	# Paso 2: una pequeña pausa antes de empezar a desvanecer (opcional, se siente mejor).
	tween.tween_interval(pause_before_fade)

	# Paso 3: la pantalla se desvanece a negro.
	tween.tween_property(fade, "color:a", 1.0, fade_duration)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

	tween.finished.connect(_on_intro_finished)


func _on_intro_finished() -> void:
	if ResourceLoader.exists(next_scene_path):
		get_tree().change_scene_to_file(next_scene_path)
	else:
		print("[BusArrival] Animación terminada (", next_scene_path, " aún no existe)")
