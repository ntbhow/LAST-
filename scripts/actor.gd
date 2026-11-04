extends CharacterBody2D
const Inventory = preload("res://scripts/inventory.gd")
const Weapon = preload("res://scripts/weapon.gd")
const Brain = preload("res://scripts/bot.gd")
const Art = preload("res://scripts/art.gd")
var game
var inv = Inventory.new()
var weapon = Weapon.new()
var brain
var is_player = false
var alive = true
var hp = 100.0
var aim_angle = 0.0
var move_input = Vector2.ZERO
var aim_point = Vector2.ZERO
var stride = 0.0
var suit = 0
var tag = "SCOUT"
var kills = 0
var damage_dealt = 0.0
var use_left = 0.0
var use_total = 0.0
var using_item = ""
var hit_flash = 0.0
var foot_timer = 0.0
var grenade_cd = 0.0
var sprint = false
var spawn_time = 0.0

func muzzle_distance() -> float:
	var id: String = inv.gun().get("id","")
	return 67.0 if id in ["rifle","dmr","shotgun"] else (55.0 if id=="smg" else 47.0)

func _ready():
	collision_layer = 2
	collision_mask = 1
	var s = CircleShape2D.new()
	s.radius = 16
	var collider = CollisionShape2D.new()
	collider.shape = s
	add_child(collider)
	weapon.actor = self
	var visual = preload("res://scripts/actor_visual.gd").new()
	visual.actor = self
	add_child(visual)
	if not is_player:
		brain = Brain.new()
		brain.actor = self
		brain.think_left = game.rng.randf()*0.25
	z_index = 2

func _physics_process(delta):
	if not alive or game.state != "playing": return
	weapon.tick(delta)
	hit_flash = maxf(0,hit_flash-delta)
	grenade_cd = maxf(0,grenade_cd-delta)
	if use_left > 0:
		use_left -= delta
		if use_left <= 0:
			hp = minf(100,hp+(100 if using_item == "medkit" else 25))
			game.audio.play("heal",position,-5)
			using_item = ""
	if is_player and not game.autoplay:
		move_input = Vector2(float(Input.is_physical_key_pressed(KEY_D))-float(Input.is_physical_key_pressed(KEY_A)),float(Input.is_physical_key_pressed(KEY_S))-float(Input.is_physical_key_pressed(KEY_W))).normalized()
		sprint = Input.is_physical_key_pressed(KEY_SHIFT)
		aim_point = game.screen_to_world(game.cursor)
		if not game.ui.inventory_open and not game.ui.map_open and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT): weapon.shoot()
	else:
		if brain == null:
			brain = Brain.new()
			brain.actor = self
		brain.tick(delta)
	aim_angle = (aim_point-position).angle()
	var speed = 210.0 if sprint else 175.0
	if use_left > 0: speed *= 0.42
	velocity = move_input.normalized()*speed
	move_and_slide()
	position = position.clamp(Vector2(20,20),Vector2(3180,3180))
	if velocity.length() > 5:
		stride += delta*velocity.length()*0.09
		foot_timer -= delta
		if foot_timer <= 0:
			foot_timer = 0.31 if sprint else 0.4
			game.audio.play("step",position,-22)
	queue_redraw()

func use_item(id: String):
	if not alive or use_left > 0 or inv.supplies[id] <= 0 or hp >= 100: return false
	inv.supplies[id] -= 1
	using_item = id
	use_total = 4.0 if id == "medkit" else 2.0
	use_left = use_total
	weapon.cancel_reload()
	game.audio.play("reload",position,-8)
	return true

func cancel_use():
	if use_left > 0:
		inv.supplies[using_item] += 1
		use_left = 0
		using_item = ""

func throw_grenade():
	if inv.supplies.grenade <= 0 or grenade_cd > 0 or use_left > 0: return
	inv.supplies.grenade -= 1
	grenade_cd = 0.7
	game.throw_grenade(self,Vector2.from_angle(aim_angle))

func damage(amount: float, source = null, zone_damage: bool = false):
	if not alive: return
	cancel_use()
	var final = amount
	if not zone_damage:
		if inv.helmet: final *= 0.92
		var absorbed = minf(inv.armor,final*0.5)
		inv.armor -= absorbed
		final -= absorbed
	var actual = minf(hp,final)
	hp = maxf(0,hp-final)
	if is_instance_valid(source):
		source.damage_dealt += actual
		if source.is_player: game.hit_marker = 0.14
	hit_flash = 0.12
	if is_player: game.shake = maxf(game.shake,2.0)
	if hp <= 0:
		alive = false
		collision_layer = 0
		collision_mask = 0
		velocity = Vector2.ZERO
		weapon.cancel_reload()
		if is_instance_valid(source) and source != self: source.kills += 1
		game.on_death(self,source)
	queue_redraw()

func _draw():
	if not alive:
		return
	# Feet translate along travel direction; upper body independently tracks aim.
	draw_set_transform(Vector2.ZERO,velocity.angle() if velocity.length()>10 else aim_angle)
	for side in [-1,1]:
		var p = Vector2((sin(stride)*11*side if velocity.length()>10 else 0)-6,side*10)
		draw_style_box(Art.box(Color("242c26"),3),Rect2(p-Vector2(5,4),Vector2(14,8)))
		draw_line(p+Vector2(-2,-2),p+Vector2(6,-2),Color("92977b"),1)
	draw_set_transform(Vector2.ZERO)
	if is_player:
		draw_arc(Vector2.ZERO,25,0.2,PI-0.2,24,Color(0.88,0.83,0.57,0.7),2,true)
	if hit_flash > 0: draw_arc(Vector2.ZERO,22,0,TAU,24,Color(1,0.8,0.6,0.7),2,true)
