extends CharacterBody2D

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var strong_attack_sfx: AudioStreamPlayer2D = $Strong_Attack_sfx
@onready var attack_sfx: AudioStreamPlayer2D = $Attack_sfx
@onready var run_sfx: AudioStreamPlayer2D = $Run_sfx
@onready var jump_sfx: AudioStreamPlayer2D = $jump_sfx
@onready var dash_sfx: AudioStreamPlayer2D = $dash_sfx
@onready var dash_atk_sfx: AudioStreamPlayer2D = $dash_atk_sfx
@onready var guard_sfx: AudioStreamPlayer2D = $guard_sfx

const GRAVITY = 1000
const SPEED = 200
const JUMP = -250
const JUMP_HORIZONTAL = 100

# Configurações de Velocidade e Dash
const DASH_SPEED = 300
const DASH_ATTACK_SPEED = 200
const ATTACK_WALK_SPEED = 50
const DASH_DURATION = 0.2
const DASH_COOLDOWN = 1.0

enum State { Idle, Run, Jump, Attack, Dash, Guard }
var current_state = State.Idle

# Variável para controlar o tempo do dash
var dash_cooldown_timer = 0.0

# Combo normal
var attack_stage = 0
var queued_attack = false

# Strong attack
var strong_attack = false

# Dash attack
var dash_attack = false

# Dash
var is_dashing = false
var dash_time = 0.0
var dash_direction = 0

# Guard
var is_guarding = false

var last_animation = ""

var attack_sfx_played = false
var is_running_sfx = false

var dash_atk_sfx_played = false

func _ready():
	animated_sprite_2d.connect("animation_finished", Callable(self, "_on_animation_finished"))

func _physics_process(delta):
	player_gravity(delta)
	player_move(delta)
	player_jump(delta)
	player_dash(delta)
	
	# --- LÓGICA DO COOLDOWN ---
	if dash_cooldown_timer > 0:
		dash_cooldown_timer -= delta

	move_and_slide()

	player_attack()
	player_state()
	player_animations()

func player_gravity(delta):
	if !is_on_floor():
		velocity.y += GRAVITY * delta

func player_move(_delta):
	if is_dashing:
		var current_speed = DASH_SPEED
		if dash_attack:
			current_speed = DASH_ATTACK_SPEED
		velocity.x = dash_direction * current_speed
		return

	if is_guarding:
		velocity.x = 0
		return

	var direction = Input.get_axis("move_left", "move_right")
	
	var current_move_speed = SPEED
	
	if current_state == State.Attack:
		current_move_speed = ATTACK_WALK_SPEED
	
	velocity.x = direction * current_move_speed

	if direction != 0:
		animated_sprite_2d.flip_h = direction < 0

func player_jump(delta):
	if is_dashing or is_guarding:
		return

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP
		jump_sfx.play()

	if !is_on_floor():
		var direction = Input.get_axis("move_left", "move_right")
		velocity.x += direction * JUMP_HORIZONTAL * delta

func player_dash(delta):
	if !is_dashing:
		return

	dash_time += delta
	if dash_time >= DASH_DURATION and !dash_attack:
		is_dashing = false

func player_attack():
	if is_dashing and !dash_attack:
		return
	
	if is_guarding:
		return

	# COMBO NORMAL
	if Input.is_action_just_pressed("attack_1"):
		if current_state != State.Attack:
			attack_stage = 1
			current_state = State.Attack
			queued_attack = false
		else:
			if attack_stage < 3:
				queued_attack = true

	# STRONG ATTACK
	if Input.is_action_just_pressed("attack_strong") and current_state != State.Attack:
		strong_attack = true
		strong_attack_sfx.play()
		current_state = State.Attack
	
	# DASH ATTACK
	if Input.is_action_just_pressed("dash_attack") and current_state != State.Attack:
		dash_attack = true
		current_state = State.Attack
		is_dashing = true
		dash_time = 0
		dash_atk_sfx_played = false
		
		dash_direction = Input.get_axis("move_left", "move_right")
		if dash_direction == 0:
			dash_direction = -1 if animated_sprite_2d.flip_h else 1
		
	# DASH COMUM
	if Input.is_action_just_pressed("dash") and current_state != State.Attack:
		# --- VERIFICAÇÃO DO COOLDOWN ---
		if dash_cooldown_timer <= 0:
			dash_cooldown_timer = DASH_COOLDOWN
			
			is_dashing = true
			dash_time = 0
			dash_sfx.play()

			dash_direction = Input.get_axis("move_left", "move_right")
			if dash_direction == 0:
				dash_direction = -1 if animated_sprite_2d.flip_h else 1

func player_state():
	if is_dashing and !dash_attack:
		current_state = State.Dash
		return

	if Input.is_action_pressed("guard") and !dash_attack and current_state != State.Attack:
		if !is_guarding:
			guard_sfx.play()
		is_guarding = true
		current_state = State.Guard
		return
	else:
		if is_guarding:
			guard_sfx.stop()
		is_guarding = false

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
	if current_state != State.Run and is_running_sfx:
		run_sfx.stop()
		is_running_sfx = false

	if current_state == State.Idle:
		animated_sprite_2d.play("idle")
		last_animation = "idle"

	elif current_state == State.Run:
		if last_animation != "run":
			animated_sprite_2d.play("run")
			run_sfx.play()
			is_running_sfx = true
			last_animation = "run"

	elif current_state == State.Jump:
		animated_sprite_2d.play("jump")
		last_animation = "jump"

	elif current_state == State.Dash:
		if last_animation != "dash":
			animated_sprite_2d.play("dash")
			last_animation = "dash"

	elif current_state == State.Guard:
		if last_animation != "guard":
			animated_sprite_2d.play("guard")
			last_animation = "guard"

	elif current_state == State.Attack:
		if strong_attack:
			if last_animation != "strong_attack":
				animated_sprite_2d.play("strong_attack")
				last_animation = "strong_attack"
			return

		if dash_attack:
			if last_animation != "dash_attack":
				animated_sprite_2d.play("dash_attack", 1.5)
				last_animation = "dash_attack"
				
				if !dash_atk_sfx_played:
					dash_atk_sfx.play()
					dash_atk_sfx_played = true
			return

		var anim = "attack_" + str(attack_stage)
		if last_animation != anim:
			animated_sprite_2d.play(anim)
			attack_sfx.play()
			attack_sfx_played = true
			last_animation = anim

func _on_animation_finished():
	if current_state == State.Dash:
		is_dashing = false
		current_state = State.Idle
		return

	if current_state != State.Attack:
		return

	if strong_attack:
		strong_attack = false
		current_state = State.Idle
		return

	if dash_attack:
		dash_attack = false
		is_dashing = false
		dash_atk_sfx_played = false
		current_state = State.Idle
		return

	if queued_attack:
		attack_stage += 1
		queued_attack = false
		attack_sfx_played = false
		return

	attack_stage = 0
	attack_sfx_played = false
	current_state = State.Idle
