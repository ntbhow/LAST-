extends RefCounted
var actor
var target = null
var last_seen = Vector2.ZERO
var memory = 0.0
var reaction = 0.0
var think_left = 0.0
var path: PackedVector2Array = PackedVector2Array()
var goal = Vector2.ZERO
var state = "SCAVENGE"
var aim_error = 0.0
var strafe = 1.0
var stuck_time = 0.0
var previous_pos = Vector2.ZERO
var repath = 0.0
var cover_left = 0.0

func can_see(other) -> bool:
	if not is_instance_valid(other) or not other.alive: return false
	if actor.position.distance_to(other.position) > 640: return false
	return clear_line(other.position)

func clear_line(point: Vector2) -> bool:
	var q = PhysicsRayQueryParameters2D.create(actor.position,point,1)
	return actor.get_world_2d().direct_space_state.intersect_ray(q).is_empty()

func tick(delta: float):
	var game = actor.game
	var hard: bool = game.settings.values.difficulty == 1
	think_left -= delta
	reaction = maxf(0,reaction-delta)
	memory -= delta
	repath -= delta
	cover_left = maxf(0,cover_left-delta)
	actor.sprint = false
	if think_left <= 0:
		think_left = 0.18+game.rng.randf()*0.12
		var seen = null
		var closest = 640.0
		for a in game.actors:
			if a == actor or not a.alive: continue
			var distance = actor.position.distance_to(a.position)
			if distance < closest and can_see(a):
				seen = a
				closest = distance
		if seen != null:
			if seen != target: reaction = 0.3 if hard else 0.65
			target = seen
			last_seen = seen.position
			memory = 2.3
		elif memory <= 0: target = null
		aim_error = game.rng.randfn(0,0.045 if hard else 0.11)
		if game.rng.randf() < 0.16: strafe *= -1
		decide()
	var visible = target != null and can_see(target)
	if state == "HEAL":
		actor.move_input = Vector2.ZERO
		if actor.use_left <= 0:
			actor.use_item("medkit" if actor.inv.supplies.medkit > 0 else "bandage")
	elif state == "FIGHT" and visible:
		var s = actor.inv.stats()
		var travel = actor.position.distance_to(target.position)/s.get("speed",800.0)
		var lead: Vector2 = target.position+target.velocity*travel*(0.9 if hard else 0.65)
		actor.aim_point = actor.position+(lead-actor.position).rotated(aim_error)
		var distance = actor.position.distance_to(target.position)
		var direction: Vector2 = (target.position-actor.position).normalized()
		var desired = 260.0 if actor.inv.gun().get("id","") != "shotgun" else 140.0
		actor.move_input = (direction*(1 if distance > desired+80 else (-1 if distance < desired-60 else 0))+direction.orthogonal()*strafe*0.65).normalized()
		if actor.inv.active == 2 and distance < 65 and reaction <= 0: actor.weapon.shoot()
		elif actor.inv.active < 2 and reaction <= 0:
			if actor.inv.gun().get("rounds",0) == 0:
				actor.weapon.reload()
				if actor.weapon.reload_left <= 0:
					var other = 1-actor.inv.active
					if not actor.inv.guns[other].is_empty(): actor.weapon.switch(other)
			else: actor.weapon.shoot()
		if actor.hp < 35 and actor.weapon.reload_left > 0:
			state = "COVER"
			cover_left = 2.5
			goal = game.cover_point(actor.position,target.position)
			path = game.find_path(actor.position,goal)
	else:
		follow_path(delta)
		actor.aim_point = actor.position+actor.move_input*100
		if target != null and memory > 0: actor.aim_point = last_seen
		actor.sprint = state == "ZONE"
		if state == "SCAVENGE":
			var near = game.nearby_loot(actor.position,55)
			if not near.is_empty():
				for l in near:
					if wants(l.item): game.pickup(actor,l); break
			for crate in game.obstacles:
				if not is_instance_valid(crate) or crate.broken or crate.kind not in ["wood","supply"]: continue
				if actor.position.distance_to(crate.position) < 70 and clear_line(crate.position-(crate.position-actor.position).normalized()*35):
					actor.aim_point = crate.position
					actor.weapon.switch(2)
					actor.weapon.shoot()
					break
	if actor.inv.active == 2 and state == "FIGHT":
		if not actor.inv.guns[0].is_empty(): actor.weapon.switch(0)
		elif not actor.inv.guns[1].is_empty(): actor.weapon.switch(1)

func wants(item: Dictionary) -> bool:
	var id: String = item.id
	if actor.inv.guns[0].is_empty() or actor.inv.guns[1].is_empty(): return true
	if id in ["rifle","dmr"] and actor.inv.guns[mini(actor.inv.active,1)].get("id","") in ["pistol","smg"]: return true
	if id.begins_with("ammo") or id in ["bandage","medkit","grenade"]: return actor.inv.used() < actor.inv.capacity()-10
	if id.begins_with("armor"): return actor.inv.armor < float(id.trim_prefix("armor"))
	if id == "helmet": return not actor.inv.helmet
	if id == "backpack": return not actor.inv.backpack
	return false

func decide():
	var game = actor.game
	var zone = game.zone
	var armed = false
	for i in 2:
		var g: Dictionary = actor.inv.guns[i]
		if not g.is_empty():
			var ammo_kind: String = game.Catalog.weapons[g.id].ammo
			if g.rounds>0 or actor.inv.ammo[ammo_kind]>0:
				armed = true
				if actor.inv.active==2 or actor.inv.gun().get("rounds",0)==0: actor.weapon.switch(i)
	if armed and not actor.inv.gun().is_empty() and actor.inv.gun().rounds==0: actor.weapon.reload()
	var outside = actor.position.distance_to(zone.next_center) > zone.next_radius-45
	if outside and (not zone.holding or zone.remaining() < 15 or actor.position.distance_to(zone.center)>zone.radius):
		state = "ZONE"
		goal = game.free_point(zone.next_center+(actor.position-zone.next_center).normalized()*maxf(0,zone.next_radius*0.6))
	elif actor.hp < 70 and (target == null or not can_see(target)) and (actor.inv.supplies.bandage+actor.inv.supplies.medkit > 0): state = "HEAL"
	elif cover_left>0 and actor.position.distance_to(goal)>35: state = "COVER"
	elif target != null and can_see(target) and (armed or actor.position.distance_to(target.position)<70): state = "FIGHT"
	elif target != null and memory > 0 and armed:
		state = "SEARCH"
		goal = last_seen
	else:
		state = "SCAVENGE"
		if actor.position.distance_to(goal) < 65 or path.is_empty():
			var nearest = 650.0
			var found = false
			for l in game.loots:
				if not is_instance_valid(l) or l.taken or not wants(l.item): continue
				var d = actor.position.distance_to(l.position)
				if d < nearest:
					nearest = d
					goal = l.position
					found = true
			if not found:
				for crate in game.obstacles:
					if not is_instance_valid(crate) or crate.broken or crate.kind not in ["wood","supply"]: continue
					var d = actor.position.distance_to(crate.position)
					if d<nearest:
						nearest = d
						goal = game.free_point(crate.position+(actor.position-crate.position).normalized()*53)
						found = true
				if not found: goal = game.free_point(actor.position+Vector2.from_angle(game.rng.randf()*TAU)*game.rng.randf_range(180,500))
	if state not in ["FIGHT","HEAL"] and repath <= 0:
		path = game.find_path(actor.position,goal)
		repath = 1.2

func follow_path(delta):
	if path.size() > 0:
		if actor.position.distance_to(path[0]) < 22: path.remove_at(0)
		actor.move_input = (path[0]-actor.position).normalized() if path.size()>0 else Vector2.ZERO
	else: actor.move_input = Vector2.ZERO
	if actor.position.distance_to(previous_pos)<0.5 and actor.move_input.length()>0: stuck_time+=delta
	else: stuck_time = maxf(0,stuck_time-delta*2)
	if stuck_time > 0.7:
		actor.move_input = actor.move_input.rotated(strafe*1.2)
		repath = 0
	if stuck_time > 1.8:
		goal = actor.game.free_point(actor.position+Vector2.from_angle(actor.game.rng.randf()*TAU)*140)
		path = actor.game.find_path(actor.position,goal)
		stuck_time = 0
	previous_pos = actor.position
