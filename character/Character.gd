extends CharacterBody2D

@onready var camera: Camera2D = $Camera2D
@onready var sprite: AnimatedSprite2D = $Sprite
@onready var actions: VBoxContainer = $HUD/M/Actions
@onready var inventory_stack: VBoxContainer = $HUD/M/Inventory

var state_key: String

var blessedness: float = 0.0

var action_options: Dictionary = {}

var inventory: Array[String] = []

var pid: int = 0
var speed: float = 15000.0
var desired_movement := Vector2():
	set(val):
		if desired_movement == val:
			return
		desired_movement = val
		if not multiplayer.has_multiplayer_peer():
			return
		if multiplayer.get_unique_id() == pid:
			send_desired_movement.rpc_id(1, desired_movement)

func _ready():
	state_key = "%d" % pid
	
	if multiplayer.get_unique_id() == pid:
		camera.make_current()
		_update_hud()
	else:
		$HUD.queue_free()
	

func _process(delta):
	if multiplayer.get_unique_id() == pid:
		desired_movement = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")

func _physics_process(delta):
	if multiplayer.is_server():
		velocity = desired_movement * speed * delta
		move_and_slide()
		
		if desired_movement.is_zero_approx():
			if sprite.animation != "default":
				sprite.animation = "default"
				sprite.play("default")
		else:
			if absf(desired_movement.x) > 0.01:
				sprite.flip_h = desired_movement.x > 0
			if sprite.animation != "move":
				sprite.play("move")
		
		BufferedSync.amend_server_state(state_key, {
			"p": position,
			"r": rotation,
			"a": sprite.animation,
			"f": sprite.flip_h
		})
	else:
		_apply_sync_state()

func _apply_sync_state():
	var s = BufferedSync.get_state(state_key)
	if not s.valid:
		if BufferedSync.got_initial_state:
			push_warning("no valid sync state")
		return
	if s.start_state != null and s.end_state != null:
		position = s.start_state["p"].lerp(s.end_state["p"], s.progress)
		rotation = lerpf(s.start_state["r"], s.end_state["r"], s.progress)
		if sprite.animation != s.start_state["a"]:
			sprite.play(s.end_state["a"])
		sprite.flip_h = s.end_state["f"]

@rpc("any_peer")
func send_desired_movement(m: Vector2):
	if multiplayer.is_server() and multiplayer.get_remote_sender_id() == pid:
		desired_movement = m

@rpc("any_peer", "reliable")
func send_action(a: String):
	if not (multiplayer.is_server() and multiplayer.get_remote_sender_id() == pid):
		return
	if a not in action_options:
		printerr("unavailable action requested from %d: " % pid, a)
	
	action_options[a].call()

func _do_action(a: String):
	send_action.rpc_id(1, a)

func grant_action(a: String, c: Callable):
	action_options[a] = c
	send_grant_action.rpc_id(pid, a)

@rpc("reliable")
func send_grant_action(a: String):
	action_options[a] = true
	var b = Button.new()
	b.text = a.capitalize()
	b.pressed.connect(_do_action.bind(a))
	actions.add_child(b)

func clear_actions():
	action_options = {}
	send_clear_actions.rpc_id(pid)

@rpc("reliable")
func send_clear_actions():
	action_options = {}
	for child in actions.get_children():
		child.queue_free()

func add_item(x: String):
	inventory.append(x)
	send_add_item.rpc_id(pid, x)

@rpc("reliable")
func send_add_item(x: String):
	inventory.append(x)
	_update_hud()

func remove_item(x: String) -> bool:
	if x not in inventory:
		return false
	inventory.erase(x)
	send_remove_item.rpc_id(pid, x)
	return true

@rpc("reliable")
func send_remove_item(x: String):
	inventory.erase(x)
	_update_hud()

func _update_hud():
	if multiplayer.get_unique_id() != pid:
		return
	
	for c in inventory_stack.get_children():
		c.queue_free()
	
	var b = Label.new()
	b.text = "Blessedness: %.2f" % blessedness
	inventory_stack.add_child(b)
	
	for x in inventory:
		var l = Label.new()
		l.text = x
		inventory_stack.add_child(l)

@rpc("reliable", "call_local")
func bless(amount: float):
	blessedness += amount
	_update_hud()
