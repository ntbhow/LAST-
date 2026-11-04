extends Node2D
# Fixed slot pool. Simulation is independent of the short cosmetic trail.
const LIMIT = 768
var slots: Array = []
var game
var live_count = 0
var shots_fired = 0

func _init():
	for i in LIMIT: slots.append({"live":false})

func spawn(start: Vector2, direction: Vector2, stats: Dictionary, shooter):
	for b in slots:
		if b.live: continue
		b.merge({"live":true,"pos":start,"prev":start,"dir":direction,"speed":stats.speed,"damage":stats.damage,"remaining":stats.range,"life":stats.range/stats.speed+0.1,"shooter":shooter,"owner_rid":shooter.get_rid()},true)
		shots_fired += 1
		return

func cast(start: Vector2, finish: Vector2, exclude: Array = []) -> Dictionary:
	var exclusions: Array[RID] = []
	exclusions.assign(exclude)
	var q = PhysicsRayQueryParameters2D.create(start,finish,3,exclusions)
	q.hit_from_inside = true
	return get_world_2d().direct_space_state.intersect_ray(q)

func _physics_process(delta):
	live_count = 0
	for b in slots:
		if not b.live: continue
		b.life -= delta
		var travel = minf(b.speed * delta, b.remaining)
		var next: Vector2 = b.pos + b.dir * travel
		var hit = cast(b.pos,next,[b.owner_rid])
		b.prev = b.pos
		if not hit.is_empty():
			b.pos = hit.position
			impact(hit,b.damage,b.shooter)
			b.live = false
		else:
			b.pos = next
			b.remaining -= travel
			b.live = b.remaining > 0 and b.life > 0
		if b.live: live_count += 1
	queue_redraw()

func impact(hit: Dictionary, amount: float, shooter):
	var object = hit.collider
	var kind = "hit" if object is CharacterBody2D else ("wood" if object.get("kind") == "wood" else "metal")
	if object.has_method("damage"): object.damage(amount, shooter)
	game.effects.burst(hit.position,kind,5)
	game.audio.play(kind,hit.position,-10)

func _draw():
	for b in slots:
		if not b.live: continue
		var length_ = minf(24,b.pos.distance_to(b.prev)+3)
		draw_line(b.pos-b.dir*length_,b.pos,Color(1,0.81,0.46,0.62),2,true)
		draw_line(b.pos-b.dir*6,b.pos,Color("fff0bd"),1.3,true)
