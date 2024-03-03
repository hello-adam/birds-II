extends Node2D

@onready var request_overlay = $RequestOverlay
@onready var request_label: RichTextLabel = $RequestOverlay/Request
@onready var request_area = $Area2D

var tier1_requests = [
	"moss",
	"stone",
	"water"
]

var active_request: String:
	set(val):
		active_request = val
		request_label.clear()
		request_label.push_outline_color(Color(0.1, 0.1, 0.1))
		request_label.push_outline_size(8)
		request_label.push_paragraph(HORIZONTAL_ALIGNMENT_CENTER)
		request_label.append_text("Bring ")
		request_label.push_color(Color(1.0, 0.5, 0.5))
		request_label.push_bold()
		request_label.append_text(active_request)
		request_label.pop()
		request_label.pop()
		request_label.append_text("...")
		request_label.pop_all()
		
		if multiplayer.is_server():
			for body in request_area.get_overlapping_bodies():
				if body.is_in_group("player"):
					body.clear_actions()
					if active_request in body.inventory:
						body.grant_action("Give %s" % active_request, fulfill_offering.bind(body))
			
			send_active_request.rpc(active_request)

var request_visible: bool = false:
	set(val):
		request_visible = val
		request_overlay.visible = val

# Called when the node enters the scene tree for the first time.
func _ready():
	active_request = "moss"

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _on_area_2d_body_entered(body: Node2D):
	if body.is_in_group("player"):
		if multiplayer.is_server():
			if active_request in body.inventory:
				body.grant_action("Give %s" % active_request, fulfill_offering.bind(body))
		request_visible = true

func _on_area_2d_body_exited(body: Node2D):
	if body.is_in_group("player"):
		if multiplayer.is_server():
			body.clear_actions()
		for other in request_area.get_overlapping_bodies():
			if other.is_in_group("player"):
				return
		request_visible = false

@rpc("reliable")
func send_active_request(r: String):
	active_request = r

func fulfill_offering(player):
	if active_request not in player.inventory:
		return
	
	player.remove_item(active_request)
	player.bless.rpc(1.0)
	active_request = tier1_requests.pick_random()
