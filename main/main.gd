extends Node

@export var rock_scene: PackedScene

var screensize = Vector2.ZERO

func _ready() -> void:
	screensize = get_viewport().get_visible_rect().size
	for i in 3:
		spawn_rock(3)
		
func spawn_rock(size: int, pos=null, vel=null) -> void:
	if pos == null:
		$RockPath/RockSpawn.progress = randi()
		pos = $RockPath/RockSpawn.position
	if vel == null:
		vel = Vector2.RIGHT.rotated(randf_range(0, TAU)) * randf_range(50, 125)
	var r := rock_scene.instantiate()
	r.screensize = screensize
	r.start(pos, vel, size)
	call_deferred("add_child", r)
	r.exploded.connect(self._on_rock_exploded)
	
func _on_rock_exploded(size: int, radius: int, pos: Vector2, vel: Vector2):
	if size <= 1:
		return
	for offset in [-1, 1]:
		var dir = $Player.position.direction_to(pos).orthogonal() * offset
		var newpos = pos + dir * radius
		var newvel = dir * vel.length() * 1.1
		spawn_rock(size - 1, newpos, newvel)