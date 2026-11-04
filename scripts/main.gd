extends Node2D
const Catalog = preload("res://scripts/catalog.gd")
const Actor = preload("res://scripts/actor.gd")
const Obstacle = preload("res://scripts/obstacle.gd")
const Loot = preload("res://scripts/loot.gd")
const Terrain = preload("res://scripts/terrain.gd")
const Zone = preload("res://scripts/zone.gd")
const Projectiles = preload("res://scripts/projectiles.gd")
const Effects = preload("res://scripts/effects.gd")
const Audio = preload("res://scripts/audio.gd")
const Settings = preload("res://scripts/settings.gd")
const UI = preload("res://scripts/ui.gd")
const Roofs = preload("res://scripts/roofs.gd")
const Grenade = preload("res://scripts/grenade.gd")
var settings = Settings.new()
var rng = RandomNumberGenerator.new()
var world: Node2D
var terrain
var zone
var projectiles
var effects
var audio
var ui
var player
var actors: Array = []
var obstacles: Array = []
var loots: Array = []
var camera: Camera2D
var nav = AStarGrid2D.new()
var state = "menu"
var elapsed = 0.0
var shake = 0.0
var hit_marker = 0.0
var cursor = Vector2(640,360)
var feed: Array = []
var rank = 0
var loot_selection = 0
var autoplay = false
var match_seed = 0
var crates_broken = 0
var pickup_count = 0
var debug_enabled = false
var result_delay = 0.0
var damage_at_death = 0.0
var seed_override = -1
var simulation_speed = 1.0
var auto_report = false
var sample_frames = 0
var sample_total = 0.0
var sample_worst = 0.0
var frame_times: Array[float] = []
var soak = false
var survived = 0.0

func _ready():
	Catalog.init_data()
	process_mode = Node.PROCESS_MODE_ALWAYS
	audio = Audio.new()
	add_child(audio)
	settings.load_settings()
	ui = UI.new()
	ui.game = self
	var canvas = CanvasLayer.new()
	add_child(canvas)
	canvas.add_child(ui)
	ui.show_menu()
	var args = OS.get_cmdline_user_args()
	if "--qa1080" in args:
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS,true)
		DisplayServer.window_set_size(Vector2i(1920,1080))
		DisplayServer.window_set_position(Vector2i.ZERO)
	soak = "--soak" in args
	for arg in args:
		if arg.begins_with("--seed="): seed_override = int(arg.split("=")[1])
		if arg.begins_with("--speed="): simulation_speed = float(arg.split("=")[1])
	if "--autoplay" in args:
		autoplay = true
		auto_report = true
		start_match(44621 if seed_override < 0 else seed_override)
		Engine.time_scale = simulation_speed
	if "--capture" in args: capture_run.call_deferred()

func start_match(seed_value: int = -1):
	get_tree().paused = false
	if is_instance_valid(world):
		remove_child(world)
		world.queue_free()
	actors.clear()
	obstacles.clear()
	loots.clear()
	feed.clear()
	match_seed = seed_value if seed_value >= 0 else (seed_override if seed_override>=0 else int(Time.get_unix_time_from_system()))
	rng.seed = match_seed
	elapsed = 0
	crates_broken = 0
	pickup_count = 0
	rank = 0
	shake = 0
	hit_marker = 0
	loot_selection = 0
	result_delay = 0
	sample_frames = 0
	sample_total = 0
	sample_worst = 0
	frame_times.clear()
	survived = 0
	world = Node2D.new()
	world.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(world)
	terrain = Terrain.new()
	terrain.game = self
	world.add_child(terrain)
	build_map()
	build_navigation()
	effects = Effects.new()
	effects.z_index = 7
	world.add_child(effects)
	projectiles = Projectiles.new()
	projectiles.game = self
	projectiles.z_index = 6
	world.add_child(projectiles)
	zone = Zone.new()
	zone.game = self
	zone.z_index = 8
	world.add_child(zone)
	player = create_actor(Vector2(930,990),true,0)
	player.suit = int(settings.values.suit)
	player.tag = "YOU"
	# A guaranteed starter cache, visible from the deployment point.
	for entry in [["pistol",Vector2(1000,1010)],["ammo_light",Vector2(1055,1015)],["bandage",Vector2(1000,1070)],["armor25",Vector2(1055,1070)]]:
		spawn_loot(Catalog.make_item(entry[0]),entry[1])
	var spawn_points: Array[Vector2] = [player.position]
	for i in 20:
		var p = free_point(Vector2(rng.randf_range(180,3020),rng.randf_range(180,3020)))
		for attempt in 80:
			var valid = true
			for used in spawn_points:
				if p.distance_to(used) < 320: valid = false; break
			if valid: break
			p = free_point(Vector2(rng.randf_range(180,3020),rng.randf_range(180,3020)))
		spawn_points.append(p)
		create_actor(p,false,i+1)
	for i in 145:
		spawn_loot(Catalog.roll("ground",rng),free_point(Vector2(rng.randf_range(100,3100),rng.randf_range(100,3100))))
	var roofs = Roofs.new()
	roofs.game = self
	roofs.z_index = 5
	world.add_child(roofs)
	camera = Camera2D.new()
	camera.position = player.position
	camera.position_smoothing_enabled = false
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = 3200
	camera.limit_bottom = 3200
	world.add_child(camera)
	var listener = AudioListener2D.new()
	player.add_child(listener)
	listener.make_current()
	state = "playing"
	ui.show_hud()
	if not autoplay: Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func create_actor(pos: Vector2, human: bool, index: int):
	var a = Actor.new()
	a.game = self
	a.position = pos
	a.is_player = human
	a.suit = index%3
	a.tag = ["ROOK","FLINT","MOSS","VALE","REED","ASH","PIKE","WREN","DUNE","SLATE"][index%10]+"-"+str(index)
	a.inv.supplies.bandage = 1
	world.add_child(a)
	actors.append(a)
	return a

func add_obstacle(type_: String, pos: Vector2, size_: Vector2):
	var o = Obstacle.new()
	o.setup(self,type_,pos,size_)
	world.add_child(o)
	obstacles.append(o)
	return o

func build_map():
	for r in terrain.buildings:
		add_obstacle("wall",Vector2(r.get_center().x,r.position.y),Vector2(r.size.x,18))
		add_obstacle("wall",Vector2(r.position.x,r.get_center().y),Vector2(18,r.size.y))
		add_obstacle("wall",Vector2(r.end.x,r.get_center().y),Vector2(18,r.size.y))
		var half = (r.size.x-100)/2
		add_obstacle("wall",Vector2(r.position.x+half/2,r.end.y),Vector2(half,18))
		add_obstacle("wall",Vector2(r.end.x-half/2,r.end.y),Vector2(half,18))
		add_obstacle("supply",r.position+Vector2(65,65),Vector2(56,42))
		add_obstacle("wood",r.position+Vector2(140,65),Vector2(48,48))
	for i in 75:
		var p = Vector2(rng.randf_range(100,3100),rng.randf_range(100,3100))
		if absf(p.x-1595)<155 or absf(p.y-1565)<155 or p.distance_to(Vector2(1000,1000))<180: continue
		var indoor = false
		for r in terrain.buildings:
			if r.grow(70).has_point(p): indoor = true
		if indoor: continue
		add_obstacle("tree" if i%3 != 0 else "rock",p,Vector2.ONE*rng.randf_range(48,88))
	for p in [Vector2(1170,1050),Vector2(1280,1110),Vector2(1880,1150),Vector2(1840,2220),Vector2(1000,2000),Vector2(2100,1850)]:
		add_obstacle("wall",p,Vector2(135,25))
		add_obstacle("wood",p+Vector2(-70,65),Vector2(48,48))
		add_obstacle("supply",p+Vector2(80,65),Vector2(56,42))
	for i in 22:
		var p = Vector2(rng.randf_range(130,3070),rng.randf_range(130,3070))
		if is_walkable(p,40): add_obstacle("wood",p,Vector2(48,48))
	add_obstacle("wall",Vector2(1600,-15),Vector2(3240,30))
	add_obstacle("wall",Vector2(1600,3215),Vector2(3240,30))
	add_obstacle("wall",Vector2(-15,1600),Vector2(30,3200))
	add_obstacle("wall",Vector2(3215,1600),Vector2(30,3200))

func is_walkable(point: Vector2, padding: float = 21) -> bool:
	if point.x < padding or point.y < padding or point.x > 3200-padding or point.y > 3200-padding: return false
	for o in obstacles:
		if not is_instance_valid(o) or o.broken: continue
		if o.kind in ["rock","tree"]:
			if point.distance_to(o.position) < o.dims.x*0.38+padding: return false
		elif Rect2(o.position-o.dims/2,o.dims).grow(padding).has_point(point): return false
	return true

func free_point(point: Vector2) -> Vector2:
	point = point.clamp(Vector2(45,45),Vector2(3155,3155))
	if is_walkable(point,28): return point
	for radius_ in range(35,500,28):
		for j in 16:
			var p = point+Vector2.from_angle(j*TAU/16)*radius_
			if is_walkable(p,28): return p
	return Vector2(930,990)

func build_navigation():
	nav.region = Rect2i(0,0,100,100)
	nav.cell_size = Vector2(32,32)
	nav.offset = Vector2(16,16)
	nav.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	nav.update()
	for y in 100:
		for x in 100:
			nav.set_point_solid(Vector2i(x,y),not is_walkable(Vector2(x*32+16,y*32+16),21))

func nav_cell(pos: Vector2) -> Vector2i:
	var cell = Vector2i(pos/32).clamp(Vector2i.ZERO,Vector2i(99,99))
	if not nav.is_point_solid(cell): return cell
	for radius_ in range(1,8):
		for y in range(-radius_,radius_+1):
			for x in range(-radius_,radius_+1):
				var c = cell+Vector2i(x,y)
				if nav.is_in_boundsv(c) and not nav.is_point_solid(c): return c
	return cell

func find_path(start: Vector2, end: Vector2) -> PackedVector2Array:
	return nav.get_point_path(nav_cell(start),nav_cell(end),true)

func cover_point(pos: Vector2, enemy: Vector2) -> Vector2:
	var closest = 400.0
	var best = pos
	for o in obstacles:
		if not is_instance_valid(o) or o.broken: continue
		var point: Vector2 = o.position+(o.position-enemy).normalized()*(o.dims.length()*0.5+35)
		var d = pos.distance_to(point)
		if d<closest and is_walkable(point): closest=d; best=point
	return best

func spawn_loot(item: Dictionary, pos: Vector2):
	if item.is_empty(): return null
	var l = Loot.new()
	l.item = item.duplicate(true)
	l.position = free_point(pos)
	l.z_index = 1
	world.add_child(l)
	loots.append(l)
	return l

func nearby_loot(pos: Vector2, distance: float = 82) -> Array:
	var found: Array = []
	for l in loots:
		if is_instance_valid(l) and not l.taken and pos.distance_to(l.position)<distance:
			var q = PhysicsRayQueryParameters2D.create(pos,l.position,1)
			if get_world_2d().direct_space_state.intersect_ray(q).is_empty(): found.append(l)
	found.sort_custom(func(a,b): return pos.distance_squared_to(a.position)<pos.distance_squared_to(b.position))
	return found

func pickup(a, l):
	if not is_instance_valid(l) or l.taken: return false
	var before: Dictionary = l.item.duplicate(true)
	var returned = a.inv.pickup(l.item)
	if returned == before: return false
	l.taken = true
	loots.erase(l)
	l.queue_free()
	if not returned.is_empty(): spawn_loot(returned,a.position+Vector2.from_angle(a.aim_angle+PI)*38)
	a.weapon.cancel_reload()
	pickup_count += 1
	audio.play("pickup",a.position,-6)
	return true

func interact():
	var near = nearby_loot(player.position)
	if not near.is_empty():
		pickup(player,near[loot_selection%near.size()])
		loot_selection = 0

func break_crate(crate, _source):
	crates_broken += 1
	for i in (3 if crate.kind == "supply" else 2):
		spawn_loot(Catalog.roll(crate.kind,rng),crate.position+Vector2.from_angle(i*TAU/3)*42)
	effects.burst(crate.position,"wood",20)
	audio.play("wood",crate.position,-2)
	# Update only the affected local navigation cells.
	var cell = Vector2i(crate.position/32)
	for y in range(cell.y-3,cell.y+4):
		for x in range(cell.x-3,cell.x+4):
			if nav.is_in_bounds(x,y): nav.set_point_solid(Vector2i(x,y),not is_walkable(Vector2(x*32+16,y*32+16),21))

func melee(a):
	var direction = Vector2.from_angle(a.aim_angle)
	var hit = projectiles.cast(a.position,a.position+direction*76,[a.get_rid()])
	if not hit.is_empty(): projectiles.impact(hit,30,a)
	audio.play("melee",a.position,-9)

func throw_grenade(a,direction: Vector2):
	var g = Grenade.new()
	g.game = self
	g.shooter = a
	g.position = a.position
	g.velocity = direction*480
	g.z_index = 4
	world.add_child(g)

func living() -> int:
	var count = 0
	for a in actors:
		if a.alive: count += 1
	return count

func on_death(a, source):
	var killer = source.tag if is_instance_valid(source) else "THE DUST"
	feed.push_front({"text":killer+"  /  "+a.tag,"time":6.0})
	if feed.size()>5: feed.pop_back()
	for i in 2: spawn_loot(a.inv.drop_gun(i),a.position+Vector2(i*45-20,25))
	for kind in a.inv.ammo:
		if a.inv.ammo[kind]>0:
			spawn_loot({"id":"ammo_"+kind,"count":a.inv.ammo[kind]},a.position+Vector2(rng.randf_range(-45,45),rng.randf_range(-45,45)))
			a.inv.ammo[kind] = 0
	for id in a.inv.supplies:
		while a.inv.supplies[id]>0: spawn_loot(a.inv.drop_supply(id),a.position+Vector2(rng.randf_range(-55,55),rng.randf_range(-55,55)))
	if a.inv.armor>0:
		spawn_loot({"id":"armor"+str(a.inv.armor),"count":1},a.position+Vector2(-42,0))
		a.inv.armor = 0
	if a.inv.helmet: spawn_loot(Catalog.make_item("helmet"),a.position+Vector2(0,-45)); a.inv.helmet = false
	if a.inv.backpack: spawn_loot(Catalog.make_item("backpack"),a.position+Vector2(42,0)); a.inv.backpack = false
	if a.is_player:
		rank = living()+1
		survived = elapsed
		if not soak: result_delay = 0.65
		damage_at_death = a.damage_dealt
	elif living() == 1 and player.alive:
		rank = 1
		result_delay = 0.65
	if soak and living()<=1: result_delay = 0.01

func finish_match():
	state = "result"
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	ui.show_result()
	if auto_report:
		frame_times.sort()
		var report = {"seed":match_seed,"rank":rank,"kills":player.kills,"damage":player.damage_dealt,"seconds":elapsed,"zone_stage":zone.stage,"alive":living(),"crates_broken":crates_broken,"pickups":pickup_count,"shots":projectiles.shots_fired,"avg_frame_ms":sample_total/maxi(sample_frames,1)*1000,"worst_frame_ms":sample_worst*1000,"p95_frame_ms":frame_times[int(frame_times.size()*0.95)]*1000 if not frame_times.is_empty() else 0,"speed":simulation_speed,"renderer":RenderingServer.get_video_adapter_name(),"resolution":str(DisplayServer.window_get_size())}
		print("MATCH_REPORT "+JSON.stringify(report))
		var report_path = "res://tests/match_report_"+str(match_seed)+".json" if not OS.has_feature("standalone") else "user://match_report.json"
		var f = FileAccess.open(report_path,FileAccess.WRITE)
		if f: f.store_string(JSON.stringify(report,"  "))
		if "--quit-result" in OS.get_cmdline_user_args(): get_tree().quit()

func screen_to_world(point: Vector2) -> Vector2:
	return get_viewport().get_canvas_transform().affine_inverse()*point

func _process(delta):
	if state == "playing" and not get_tree().paused:
		elapsed += delta
		hit_marker = maxf(0,hit_marker-delta)
		shake = move_toward(shake,0,delta*15)
		var look = (cursor-get_viewport_rect().size/2)*0.10
		var follow = player
		if soak and not player.alive:
			for a in actors:
				if a.alive: follow=a; break
		camera.position = camera.position.lerp(follow.position+look,1-exp(-delta*14))
		camera.offset = Vector2(randf_range(-1,1),randf_range(-1,1))*shake*settings.values.shake
		for item in feed: item.time -= delta
		if result_delay > 0:
			result_delay -= delta
			if result_delay <= 0: finish_match()
		if elapsed>3:
			sample_frames += 1
			sample_total += delta / Engine.time_scale
			sample_worst = maxf(sample_worst,delta/Engine.time_scale)
			frame_times.append(delta/Engine.time_scale)
	if state == "playing": ui.queue_redraw()

func _unhandled_input(event):
	if event is InputEventMouseMotion:
		cursor = (cursor+event.relative*settings.values.sensitivity).clamp(Vector2.ZERO,get_viewport_rect().size)
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_F3: debug_enabled = not debug_enabled
		if event.physical_keycode == KEY_ESCAPE:
			if state == "playing":
				if ui.inventory_open or ui.map_open: ui.inventory_open=false; ui.map_open=false; ui.show_hud()
				else: ui.show_pause()
			elif state == "paused": ui.resume()
		if state != "playing" or not player.alive: return
		match event.physical_keycode:
			KEY_R: player.weapon.reload()
			KEY_E: interact()
			KEY_1: player.weapon.switch(0)
			KEY_2: player.weapon.switch(1)
			KEY_3: player.weapon.switch(2)
			KEY_H: player.use_item("bandage")
			KEY_J: player.use_item("medkit")
			KEY_G: player.throw_grenade()
			KEY_X: player.cancel_use()
			KEY_TAB: ui.toggle_inventory()
			KEY_M: ui.map_open = not ui.map_open; ui.inventory_open=false; ui.show_hud()
			KEY_Q: loot_selection += 1
	if event is InputEventMouseButton and event.pressed and state == "playing":
		if event.button_index == MOUSE_BUTTON_WHEEL_UP or event.button_index == MOUSE_BUTTON_WHEEL_DOWN: loot_selection += 1

func capture_run():
	await get_tree().process_frame
	await get_tree().process_frame
	get_viewport().get_texture().get_image().save_png("res://tests/menu_"+str(DisplayServer.window_get_size().x)+".png")
	start_match(44621)
	# Staged visual QA loadout; normal deployment still starts with the knife.
	player.inv.pickup(Catalog.make_item("rifle"))
	player.inv.pickup(Catalog.make_item("smg"))
	player.inv.pickup(Catalog.make_item("armor50"))
	player.inv.pickup(Catalog.make_item("helmet"))
	player.inv.pickup(Catalog.make_item("backpack"))
	player.inv.ammo.heavy = 54
	player.inv.ammo.light = 60
	player.inv.supplies.grenade = 2
	player.inv.supplies.medkit = 1
	player.weapon.switch(0)
	await get_tree().create_timer(1.0).timeout
	get_viewport().get_texture().get_image().save_png("res://tests/game_"+str(DisplayServer.window_get_size().x)+".png")
	ui.toggle_inventory()
	await get_tree().process_frame
	await get_tree().process_frame
	get_viewport().get_texture().get_image().save_png("res://tests/inventory_"+str(DisplayServer.window_get_size().x)+".png")
	get_tree().quit()
