extends CharacterBody2D

@export var max_speed := 320.0
@export var acceleration := 900.0
@export var brake_power := 1400.0
@export var reverse_speed := 160.0
@export var turn_speed := 4.0
@export var friction := 650.0
@export var drift_grip := 0.85

@export var boost_drain := 100
@export var boost_recharge := 3

@export var tyremark_color_asphalt := Color.BLACK
@export var tyremark_color_dirt := Color("522c00")
@export var tyremark_width := 1.5

@export var total_laps := 3
var current_lap := 1

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var engine := $EngineSound
@onready var skid := $SkidSound
@onready var brake_sound := $BrakeSound
@onready var tyres := $Tyres.get_children()
@onready var tyremark_container := get_tree().current_scene.get_node("TyremarkContainer") # global container
@onready var ground_sensor := $asphaltraycast
@onready var ground_sensor_2 := $dirtraycast
@onready var ground_sensor_3 := $waterraycast

@export var speed_label: Label
@export var boost_label: Label
@export var lap_label: Label
@export var position_label: Label

var speed := 0.0
var turn_dir := 0
var drift := false
var boost := 100.0
var progress := 0.0

signal lap_changed(lap)
signal race_finished()

func _ready() -> void:
	pass

func _physics_process(delta):
	handle_input(delta)
	handle_rotation(delta)
	handle_movement()
	handle_animation()
	handle_sounds()
	handle_tyres()
	update_ui()
	move_and_slide()

func handle_input(delta):
	turn_dir = int(Input.is_action_pressed("right")) - int(Input.is_action_pressed("left"))

	if Input.is_action_pressed("forward"):
		speed += acceleration * delta
	elif Input.is_action_pressed("back"):
		speed -= brake_power * delta
		if not brake_sound.playing:
			brake_sound.play()
	else:
		speed = move_toward(speed, 0, friction * delta)

	# Boost
	if Input.is_action_pressed("boost") and boost > 0:
		max_speed = 500
		speed += 300 * delta
		boost -= boost_drain * delta
	else:
		max_speed = 200
		boost = min(boost + boost_recharge * delta, 100)

	speed = clamp(speed, -reverse_speed, max_speed)

	drift = Input.is_action_pressed("drift") and abs(speed) > 50

func handle_rotation(delta):
	if abs(speed) > 10:
		var grip = drift_grip if drift else 1.0
		rotation += turn_dir * turn_speed * delta * sign(speed) * grip

func handle_movement():
	var forward = Vector2.UP.rotated(rotation)
	var right = Vector2(forward.y, -forward.x)
	if drift:
		velocity = forward * speed + right * speed * 0.3
	else:
		velocity = forward * speed

func handle_animation():
	if abs(speed) < 5:
		sprite.play("default")
	elif turn_dir < 0:
		sprite.play("steerleft")
	elif turn_dir > 0:
		sprite.play("steerright")
	else:
		sprite.play("default")

func handle_sounds():
	engine.pitch_scale = lerp(0.8, 1.6, abs(speed) / max_speed)
	if drift:
		if not skid.playing:
			skid.play()
	else:
		skid.stop()

func handle_tyres():
	for tyre in tyres:
		if drift:
			draw_tyremark(tyre.global_position)

func draw_tyremark(pos: Vector2):
	if ground_sensor.has_overlapping_bodies():
		var line = Line2D.new()
		line.default_color = tyremark_color_asphalt
		line.width = tyremark_width
		line.add_point(pos)
		line.add_point(pos - Vector2.UP.rotated(rotation) * 8)
		tyremark_container.add_child(line)
	if ground_sensor_2.has_overlapping_bodies():
		var line = Line2D.new()
		line.default_color = tyremark_color_dirt
		line.width = tyremark_width
		line.add_point(pos)
		line.add_point(pos - Vector2.UP.rotated(rotation) * 8)
		tyremark_container.add_child(line)

func car_passed_line():
	current_lap += 1
	emit_signal("lap_changed", current_lap)
	if current_lap > total_laps:
		emit_signal("race_finished")

func update_ui():
	if speed_label:
		speed_label.text = "Speed: %d km/h" % int(abs(speed))
	if boost_label:
		boost_label.text = "Boost: %d%%" % int(boost)
	if lap_label:
		lap_label.text = "Lap: %d / %d" % [current_lap, total_laps]
