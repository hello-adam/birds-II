extends Node2D

var character_scn = preload("res://character/Character.tscn")
@onready var players_root = $Players

@onready var spawn_center: Node2D = $World/SpawnCenter

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _on_jam_connect_player_verified(pid, pinfo):
	print("Player joined: ", pid, pinfo)
	
	var p = character_scn.instantiate()
	p.pid = pid
	p.position = spawn_center.position + Vector2(randf_range(-500, 500), randf_range(-500, 500))
	players_root.add_child(p, true)

func _on_jam_connect_player_disconnected(pid, pinfo):
	print("Player disconnected: ", pid, pinfo)
	
