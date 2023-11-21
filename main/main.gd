extends Node

@export var rock_scene: PackedScene

var screensize = Vector2.ZERO

var level := 0
var score := 0
var playing := false

func _ready() -> void:
	screensize = get_viewport().get_visible_rect().size
	for i in 3:
		spawn_rock(3)
		
func _process(delta: float) -> void:
	if not playing:
		return
	if get_tree().get_nodes_in_group("rocks").size() == 0:
		new_level()
		
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
		
func new_game() -> void:
	get_tree().call_group("rocks", "queue_free");
	level = 0
	score = 0
	$HUD.update_score(score)
	$HUD.show_message("Get Ready!")
	$Player.reset()
	await $HUD/Timer.timeout
	playing = true

func new_level() -> void:
	level += 1
	($HUD as HUD).show_message("Wave %s" % level)
	for i in level:
		spawn_rock(3)

func game_over() -> void:
	playing = false
	$HUD.game_over()
	
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if not playing:
			return
		get_tree().paused = not get_tree().paused
		var message = $HUD/VBoxContainer/Message
		if get_tree().paused:
			message.text = "Paused"
			message.show()
		else:
			message.text = ""
			message.hide()
