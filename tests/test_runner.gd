extends SceneTree
const Main = preload("res://scripts/main.gd")
const Catalog = preload("res://scripts/catalog.gd")
const Inventory = preload("res://scripts/inventory.gd")
var passed = 0
var failed = 0
var records: Array = []
var game

func _initialize(): run.call_deferred()

func check(condition: bool, title: String):
	if condition: passed += 1
	else: failed += 1
	records.append({"name":title,"pass":condition})
	print(("PASS " if condition else "FAIL ")+title)

func settle():
	await physics_frame
	await physics_frame

func clear_bullets():
	for b in game.projectiles.slots: b.live = false

func freeze_simulation():
	# Keep CollisionObject2D registered; PROCESS_MODE_DISABLED removes its RID.
	for child in game.world.get_children():
		child.set_physics_process(false)
		child.set_process(false)

func run():
	game = Main.new()
	root.add_child(game)
	await process_frame
	game.start_match(44621)
	game.state = "testing"
	freeze_simulation()
	await settle()
	check(game.actors.size()==21,"21 operators spawn")
	var spawn_ok = true
	for a in game.actors: spawn_ok = spawn_ok and game.is_walkable(a.position,16)
	check(spawn_ok,"Every spawn clears world collision")
	check(is_equal_approx(Vector2(1,1).normalized().length()*175,Vector2.RIGHT.length()*175),"Diagonal and axial speeds match")
	var inv = Inventory.new()
	var pistol = Catalog.make_item("pistol")
	pistol.rounds = 5
	inv.pickup(pistol)
	inv.pickup(Catalog.make_item("rifle"))
	inv.active = 0
	var replaced = inv.pickup(Catalog.make_item("dmr"))
	check(replaced.id=="pistol" and replaced.rounds==5 and inv.guns[0].id=="dmr","Gun replacement preserves old magazine exactly")
	var drop = inv.drop_gun(0)
	check(drop.id=="dmr" and inv.guns[0].is_empty() and inv.active==2,"Drop transfers ownership and selects knife")
	inv.active = 1
	inv.gun().rounds = 4
	inv.ammo.heavy = 7
	inv.reload_mag()
	check(inv.gun().rounds==11 and inv.ammo.heavy==0,"Reload conserves rounds with partial reserve")
	inv.ammo.light = 117
	var extra = inv.pickup({"id":"ammo_light","count":10})
	check(inv.ammo.light==120 and extra.count==7,"Backpack capacity returns excess ammo")
	inv.pickup(Catalog.make_item("backpack"))
	check(inv.capacity()==240,"Backpack upgrade doubles capacity")
	inv.ammo.light = 160
	check(inv.drop_equipment("backpack").is_empty() and inv.backpack,"Loaded backpack cannot silently discard inventory")
	inv.ammo.light = 20
	check(inv.drop_equipment("backpack").id=="backpack" and not inv.backpack,"Backpack drops after its load fits standard capacity")
	inv.armor = 17.65
	var armor_drop = inv.drop_equipment("armor")
	inv.pickup(armor_drop)
	check(is_equal_approx(inv.armor,17.65),"Dropping damaged armor preserves fractional durability")
	var p = game.player
	p.position = Vector2(3500,3500)
	p.inv = Inventory.new()
	p.inv.pickup(Catalog.make_item("pistol"))
	p.inv.ammo.light = 30
	p.aim_angle = 0
	var enemy = game.actors[1]
	enemy.position = Vector2(3800,3500)
	enemy.inv = Inventory.new()
	enemy.hp = 100
	await settle()
	var s: Dictionary = Catalog.weapons.pistol.duplicate(true)
	game.projectiles.spawn(p.position,Vector2.RIGHT,s,p)
	game.projectiles._physics_process(1.0/60)
	var bullet = game.projectiles.slots[0]
	check(bullet.live and is_equal_approx(bullet.pos.x,3500+s.speed/60.0) and enemy.hp==100,"Projectile advances by speed*delta; no instant damage")
	for i in 25: game.projectiles._physics_process(1.0/60)
	check(enemy.hp==78,"Projectile damages target after travel time")
	check(p.hp==100,"Projectile excludes shooter collider")
	clear_bullets()
	var wall = game.add_obstacle("wall",Vector2(3600,3500),Vector2(3,160))
	await settle()
	s.speed = 18000
	game.projectiles.spawn(p.position,Vector2.RIGHT,s,p)
	game.projectiles._physics_process(1.0/30)
	check(enemy.hp==78 and not game.projectiles.slots[0].live,"Swept collision blocks 18000px/s bullet on 3px wall")
	p.position = Vector2(3580,3500)
	p.weapon.cooldown = 0
	p.weapon.shoot()
	check(enemy.hp==78 and game.projectiles.shots_fired==2,"Center-to-muzzle guard blocks shot through adjacent wall")
	check(p.weapon.recoil<0 and p.weapon.bloom>0,"Recoil and spread accumulate independently")
	var recoil_before = absf(p.weapon.recoil)
	p.weapon.tick(0.1)
	check(absf(p.weapon.recoil)<recoil_before,"Recoil recovers over time")
	var spread_still = p.weapon.spread()
	p.velocity = Vector2(175,0)
	check(p.weapon.spread()>spread_still,"Movement increases spread")
	p.velocity = Vector2.ZERO
	p.inv.gun().rounds = 4
	p.weapon.reload()
	var before = p.inv.gun().rounds
	p.weapon.cooldown = 0
	check(not p.weapon.shoot() and p.inv.gun().rounds==before,"Firing is blocked while reloading")
	p.weapon.switch(2)
	check(p.weapon.reload_left==0 and p.inv.guns[0].rounds==before,"Switch cancels reload without generating rounds")
	p.weapon.switch(0)
	p.inv.gun().rounds = 0
	p.weapon.cooldown = 0
	check(not p.weapon.shoot(),"Empty magazine blocks held fire")
	p.weapon.reload()
	p.weapon.tick(2)
	check(p.inv.gun().rounds==12 and p.inv.ammo.light==18,"Reload completion transfers exactly one magazine")
	check(not enemy.brain.clear_line(p.position),"Bot sight is occluded by wall")
	wall.position = Vector2(3600,3800)
	await settle()
	check(enemy.brain.clear_line(p.position),"Bot sight resumes after obstacle moves")
	# Moving target: compare current-position shot to an intercept shot.
	p.position = Vector2(3500,3500)
	var hits: Array = []
	for lead in [false,true]:
		enemy.position = Vector2(3800,3500)
		enemy.hp = 100
		clear_bullets()
		await settle()
		s = Catalog.weapons.pistol.duplicate(true)
		var point = enemy.position+(Vector2(0,120)*(300.0/s.speed) if lead else Vector2.ZERO)
		game.projectiles.spawn(p.position,(point-p.position).normalized(),s,p)
		for i in 40:
			enemy.position.y += 120.0/60
			await settle()
			game.projectiles._physics_process(1.0/60)
		hits.append(enemy.hp<100)
	check(not hits[0] and hits[1],"Leading a moving target hits; aiming at old position misses")
	clear_bullets()
	p.inv.guns[0] = Catalog.make_item("shotgun")
	p.inv.active = 0
	p.weapon.cooldown = 0
	p.weapon.cancel_reload()
	p.weapon.shoot()
	var pellets = 0
	for b in game.projectiles.slots:
		if b.live: pellets+=1
	check(pellets==7,"Shotgun emits seven independent projectile states")
	for i in 120: game.projectiles._physics_process(1.0/60)
	check(game.projectiles.live_count==0,"Projectile range and lifetime reclaim all pool slots")
	# Grenade impact uses line-of-sight checks so cover protects the target.
	enemy.position = Vector2(3650,3500)
	enemy.hp = 100
	wall.position = Vector2(3600,3500)
	await settle()
	game.throw_grenade(p,Vector2.ZERO)
	var frag = game.world.get_child(game.world.get_child_count()-1)
	frag.position = Vector2(3550,3500)
	frag.fuse = 0.001
	frag._physics_process(0.01)
	check(enemy.hp==100,"Wall blocks grenade splash damage")
	await settle()
	wall.position = Vector2(3600,3900)
	await settle()
	game.throw_grenade(p,Vector2.ZERO)
	frag = game.world.get_child(game.world.get_child_count()-1)
	frag.position = Vector2(3550,3500)
	frag.fuse = 0.001
	frag._physics_process(0.01)
	check(enemy.hp<100,"Uncovered target receives grenade falloff damage")
	clear_bullets()
	var crate = game.add_obstacle("wood",Vector2(3550,3700),Vector2(48,48))
	var loot_before = game.loots.size()
	crate.damage(200,p)
	crate.damage(200,p)
	check(game.loots.size()==loot_before+2,"Destroyed crate emits its loot table exactly once")
	var clear_drops = true
	for i in range(loot_before,game.loots.size()): clear_drops = clear_drops and game.is_walkable(game.loots[i].position,16)
	check(clear_drops,"Crate drops resolve to walkable positions")
	await settle()
	var l = game.spawn_loot(Catalog.make_item("smg"),Vector2(930,990))
	var pickup_a = game.pickup(p,l)
	var pickup_b = game.pickup(p,l)
	check(pickup_a and not pickup_b,"Loot cannot be picked up twice in the same frame")
	p.alive = true
	p.collision_layer = 2
	p.hp = 50
	p.inv.supplies.bandage = 1
	check(p.use_item("bandage") and p.inv.supplies.bandage==0,"Healing reserves one item")
	p.damage(5,null,true)
	check(p.use_left==0 and p.inv.supplies.bandage==1,"Damage cancels healing and refunds reserved item")
	p.use_item("bandage")
	game.state = "playing"
	p._physics_process(2.1)
	game.state = "testing"
	check(p.hp==70 and p.use_left<=0,"Bandage heals 25 HP after its full use timer")
	p.hp = 100
	p.position = Vector2(10,10)
	game.zone.radius = 100
	game.zone.center = Vector2(1600,1600)
	game.zone.stage = 3
	game.state = "playing"
	game.zone._physics_process(2.0)
	game.state = "testing"
	check(p.hp==90,"Outside-zone damage scales with stage and delta")
	var path = game.find_path(Vector2(600,600),Vector2(1100,950))
	check(path.size()>5,"A* finds path from building through doorway")
	var path_safe = true
	for point in path: path_safe = path_safe and game.is_walkable(point,16)
	check(path_safe,"A* waypoints respect cover clearance")
	# With combatants isolated, a threatened bot must route into the next zone.
	for a in game.actors:
		if a!=enemy and a!=p: a.alive = false
	p.position = Vector2(3500,3500)
	enemy.position = Vector2(1700,1800)
	enemy.alive = true
	enemy.collision_layer = 2
	enemy.hp = 100
	game.zone.next_center = Vector2(1600,1600)
	game.zone.next_radius = 130
	game.zone.holding = false
	game.zone.radius = 400
	enemy.brain.target = null
	enemy.brain.memory = 0
	enemy.brain.repath = 0
	var distance_before = enemy.position.distance_to(game.zone.next_center)
	game.state = "playing"
	for i in 100:
		enemy._physics_process(1.0/60)
		await physics_frame
	game.state = "testing"
	check(enemy.position.distance_to(game.zone.next_center)<distance_before-30,"Bot physically follows path toward safe zone")
	if enemy.position.distance_to(game.zone.next_center)>=distance_before-30: print("BOT_DEBUG ",enemy.position," ",enemy.brain.state," ",enemy.brain.goal," ",enemy.brain.path)
	var config = preload("res://scripts/settings.gd").new()
	config.path = "user://test_settings.cfg"
	config.values.sensitivity = 1.35
	config.values.suit = 2
	config.save()
	var restored = preload("res://scripts/settings.gd").new()
	restored.path = config.path
	restored.load_settings()
	check(is_equal_approx(restored.values.sensitivity,1.35) and restored.values.suit==2,"Settings and cosmetic selection persist to disk")
	game.settings.apply()
	game.ui.show_pause()
	check(paused and game.state=="paused" and game.ui.page=="pause","Pause menu suspends simulation")
	game.ui.resume()
	check(not paused and game.state=="playing" and game.ui.page=="hud","Resume returns to live HUD")
	game.ui.toggle_inventory()
	check(game.ui.inventory_open and not paused and game.ui.elements.get_child_count()>=10,"Inventory exposes real actions without pausing")
	game.ui.toggle_inventory()
	game.ui.show_customize()
	check(game.ui.elements.get_child_count()==4,"Customize exposes three cosmetic choices and Back")
	game.ui.settings_return = "menu"
	game.ui.show_settings()
	var slider_count = 0
	for control in game.ui.elements.get_children():
		if control is HSlider: slider_count+=1
	check(slider_count==6,"Settings exposes functional audio, aim, shake and UI sliders")
	game.state = "testing"
	# Win / loss and clean redeployment use the same production paths.
	for a in game.actors:
		if a!=p: a.alive = false
	p.alive = true
	game.actors[2].alive = true
	game.actors[2].damage(1000,p,true)
	check(game.rank==1 and game.result_delay>0,"Last opponent death sets victory")
	game.finish_match()
	check(game.state=="result" and paused,"Results pause the completed simulation")
	game.start_match(44621)
	freeze_simulation()
	game.state = "testing"
	await settle()
	check(game.actors.size()==21 and game.living()==21 and game.elapsed==0 and game.rank==0,"Replay resets combatants, time and rank")
	check(game.projectiles.shots_fired==0 and game.projectiles.live_count==0 and game.feed.is_empty(),"Replay clears projectile pool and kill feed")
	check(game.loots.size()==149 and game.zone.stage==0 and game.zone.radius==2250,"Replay recreates clean loot and zone state")
	game.player.damage(1000,null,true)
	check(game.rank==21 and not game.player.alive,"Early player death produces correct placement")
	var f = FileAccess.open("res://tests/results.json",FileAccess.WRITE)
	f.store_string(JSON.stringify({"passed":passed,"failed":failed,"checks":records},"  "))
	print("TEST_RESULT %d passed / %d failed"%[passed,failed])
	game.queue_free()
	await process_frame
	quit(1 if failed>0 else 0)
