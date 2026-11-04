extends RefCounted
var actor
var cooldown = 0.0
var reload_left = 0.0
var recoil = 0.0
var bloom = 0.0
var pattern_index = 0
var kick = 0.0
var muzzle_flash = 0.0
var melee_left = 0.0

func tick(delta: float):
	cooldown = maxf(0,cooldown-delta)
	kick = move_toward(kick,0,delta*10)
	muzzle_flash = maxf(0,muzzle_flash-delta)
	melee_left = maxf(0,melee_left-delta)
	var stats = actor.inv.stats()
	recoil = move_toward(recoil,0,delta*stats.get("recovery",0.2))
	bloom = move_toward(bloom,0,delta*0.07)
	if reload_left > 0:
		reload_left -= delta
		if reload_left <= 0: actor.inv.reload_mag()

func switch(slot: int):
	if slot == actor.inv.active: return
	actor.inv.active = slot
	cancel_reload()
	recoil = 0
	bloom = 0
	pattern_index = 0

func cancel_reload(): reload_left = 0

func reload():
	var g = actor.inv.gun()
	var s = actor.inv.stats()
	if g.is_empty() or reload_left > 0 or actor.use_left > 0: return
	if g.rounds >= s.mag or actor.inv.ammo[s.ammo] == 0: return
	reload_left = s.reload
	actor.game.audio.play("reload",actor.position,-7)

func spread() -> float:
	return actor.inv.stats().get("spread",0.01) + bloom + (0.04 if actor.velocity.length() > 40 else 0.0)

func shoot():
	if not actor.alive or cooldown > 0 or reload_left > 0 or actor.use_left > 0: return false
	var g = actor.inv.gun()
	if g.is_empty():
		if actor.inv.active != 2: return false
		cooldown = 0.45
		melee_left = 0.28
		actor.game.melee(actor)
		return true
	if g.rounds <= 0: return false
	var s = actor.inv.stats()
	g.rounds -= 1
	cooldown = s.rate
	kick = 1
	muzzle_flash = 0.045
	var direction = Vector2.from_angle(actor.aim_angle + recoil)
	var muzzle: Vector2 = actor.position + direction * actor.muzzle_distance()
	# Check center-to-muzzle first: a barrel cannot teleport shots through a wall.
	var obstruction = actor.game.projectiles.cast(actor.position,muzzle,[actor.get_rid()])
	for i in int(s.pellets):
		if not obstruction.is_empty():
			actor.game.projectiles.impact(obstruction,s.damage,actor)
		else:
			var deviation = actor.game.rng.randf_range(-spread(),spread())
			actor.game.projectiles.spawn(muzzle,direction.rotated(deviation),s,actor)
	var pattern: Array = s.pattern
	recoil = clampf(recoil - s.kick + pattern[pattern_index % pattern.size()] * s.kick * 0.45,-s.cap,s.cap)
	pattern_index += 1
	bloom = minf(0.075,bloom+0.006)
	actor.game.audio.play(g.id,actor.position,-3)
	actor.game.effects.burst(muzzle,"smoke",2)
	actor.game.effects.burst(actor.position+direction*23,"casing",1,actor.aim_angle)
	if actor.is_player: actor.game.shake = minf(5,actor.game.shake+1.8)
	return true
