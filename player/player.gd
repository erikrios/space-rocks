extends RigidBody2D

@export var engine_power := 500
@export var spin_power := 8000

@export var bullet_scene: PackedScene
@export var fire_rate := 0.25

var can_shoot := true

var thrust := Vector2.ZERO
var rotation_dir := 0

var screensize = Vector2.ZERO

enum PlayerState {INIT, ALIVE, INVULNERABLE, DEAD}
var state := PlayerState.INIT

signal lives_changed
signal dead

var reset_pos := false
var lives := 0: set = set_lives

func set_lives(value: int):
	lives = value
	lives_changed.emit(lives)
	if lives <= 0:
		change_state(PlayerState.DEAD)
	else:
		change_state(PlayerState.INVULNERABLE)

func _ready() -> void:
	change_state(PlayerState.ALIVE)
	screensize = get_viewport_rect().size
	$GunCooldown.wait_time = fire_rate
	
func _process(delta: float) -> void:
	get_input()
	
func _physics_process(delta: float) -> void:
	constant_force = thrust
	constant_torque = rotation_dir * spin_power
	
func _integrate_forces(physics_state: PhysicsDirectBodyState2D) -> void:
	var xform := physics_state.transform
	xform.origin.x = wrapf(xform.origin.x, 0, screensize.x)
	xform.origin.y = wrapf(xform.origin.y, 0, screensize.y)
	physics_state.transform = xform
	if reset_pos:
		physics_state.transform.origin = screensize / 2
		reset_pos = false
	
func change_state(new_state: PlayerState) -> void:
	match new_state:
		PlayerState.INIT:
			$CollisionShape2D.set_deferred("disabled", true)
			$Sprite2D.modulate.a = 0.5
		PlayerState.ALIVE:
			$CollisionShape2D.set_deferred("disabled", false)
			$Sprite2D.modulate.a = 1.0
		PlayerState.INVULNERABLE:
			$CollisionShape2D.set_deferred("disabled", true)
			$Sprite2D.modulate.a = 0.5
			$InvulnerabilityTimer.start()
		PlayerState.DEAD:
			$CollisionShape2D.set_deferred("disabled", true)
			$Sprite2D.hide()
			linear_velocity = Vector2.ZERO
			dead.emit()
	state = new_state

func get_input() -> void:
	thrust = Vector2.ZERO
	if state in [PlayerState.DEAD, PlayerState.INIT]:
		return
	if Input.is_action_pressed("thrust"):
		thrust = transform.x * engine_power
	rotation_dir = Input.get_axis("rotate_left", "rotate_right")
	if Input.is_action_pressed("shoot") and can_shoot:
		shoot()

func shoot() -> void:
	if state == PlayerState.INVULNERABLE:
		return
	can_shoot = false
	$GunCooldown.start()
	var b := bullet_scene.instantiate()
	get_tree().root.add_child(b)
	b.start($Muzzle.global_transform)

func reset() -> void:
	reset_pos = true
	$Sprite2D.show()
	lives = 3
	change_state(PlayerState.ALIVE)
	
func explode():
	$Explosion.show()
	$Explosion/AnimationPlayer.play("explosion")
	await $Explosion/AnimationPlayer.animation_finished
	$Explosion.hide()

func _on_gun_cooldown_timeout() -> void:
	can_shoot = true


func _on_invulnerability_timer_timeout() -> void:
	change_state(PlayerState.ALIVE)


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("rocks"):
		body.explode()
		lives -= 1
		explode()
