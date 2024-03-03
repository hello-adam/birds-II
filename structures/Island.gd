extends Node2D

var resources: Array[String] = ["moss"]
@onready var interaction: Area2D = $Interaction

func _ready():
	pass # Replace with function body.

func _process(delta):
	pass

func _on_interaction_body_entered(body):
	if multiplayer.is_server():
		if body.is_in_group("player"):
			for r in resources:
				body.grant_action("Take %s" % r, harvest_resource.bind(body, r))

func _on_interaction_body_exited(body):
	if multiplayer.is_server():
		if body.is_in_group("player"):
			body.clear_actions()

func harvest_resource(player, r: String):
	if r not in resources:
		return
	
	resources.erase(r)
	player.add_item(r)
	
	for body in interaction.get_overlapping_bodies():
		if body.is_in_group("player"):
			body.clear_actions()
			for remaining in resources:
				body.grant_action("Take %s" % remaining)
