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
	
func change_state(new_state: PlayerState) -> void:
	match new_state:
		PlayerState.INIT:
			$CollisionShape2D.set_deferred("disabled", true)
		PlayerState.ALIVE:
			$CollisionShape2D.set_deferred("disabled", false)
		PlayerState.INVULNERABLE:
			$CollisionShape2D.set_deferred("disabled", true)
		PlayerState.DEAD:
			$CollisionShape2D.set_deferred("disabled", true)
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

func shoot():
	if state == PlayerState.INVULNERABLE:
		return
	can_shoot = false
	$GunCooldown.start()
	var b := bullet_scene.instantiate()
	get_tree().root.add_child(b)
	b.start($Muzzle.global_transform)


func _on_gun_cooldown_timeout() -> void:
	can_shoot = true
