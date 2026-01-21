extends CharacterBody2D

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

const GRAVITY = 1000
const SPEED = 300
const JUMP = -250
const JUMP_HORIZONTAL = 100

enum State { Idle, Run, Jump, Attack }
var current_state = State.Idle

var attack_stage = 0
var queued_attack = false
var last_animation = ""

func _ready():
	animated_sprite_2d.connect("animation_finished", Callable(self, "_on_animation_finished"))


func _physics_process(delta):
	player_gravity(delta)
	player_move(delta)
	player_jump(delta)

	move_and_slide()

	player_attack()
	player_state()
	player_animations()


func player_gravity(delta):
	if !is_on_floor():
		velocity.y += GRAVITY * delta


func player_move(delta):
	var direction = Input.get_axis("move_left", "move_right")
	velocity.x = direction * SPEED

	if direction != 0:
		animated_sprite_2d.flip_h = direction < 0


func player_jump(delta):
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP

	if !is_on_floor():
		var direction = Input.get_axis("move_left", "move_right")
		velocity.x += direction * JUMP_HORIZONTAL * delta


func player_attack():
	if Input.is_action_just_pressed("attack_1"):

		if current_state != State.Attack:
			attack_stage = 1
			current_state = State.Attack
			queued_attack = false

		else:
			if attack_stage < 3:
				queued_attack = true


func player_state():
	if current_state == State.Attack:
		return

	if !is_on_floor():
		current_state = State.Jump
	else:
		var direction = Input.get_axis("move_left", "move_right")
		if direction != 0:
			current_state = State.Run
		else:
			current_state = State.Idle


func player_animations():
	if current_state == State.Idle:
		animated_sprite_2d.play("idle")
		last_animation = "idle"

	elif current_state == State.Run:
		animated_sprite_2d.play("run")
		last_animation = "run"

	elif current_state == State.Jump:
		animated_sprite_2d.play("jump")
		last_animation = "jump"

	elif current_state == State.Attack:
		var anim = "attack_" + str(attack_stage)

		if last_animation != anim:
			animated_sprite_2d.play(anim)
			last_animation = anim


func _on_animation_finished():
	if current_state != State.Attack:
		return

	if queued_attack:
		attack_stage += 1
		queued_attack = false
		return

	attack_stage = 0
	current_state = State.Idle
