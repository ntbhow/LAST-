extends Node2D
const Art = preload("res://scripts/art.gd")
var game
var shooter
var velocity = Vector2.ZERO
var fuse = 1.5
func _physics_process(delta):
	var q = PhysicsRayQueryParameters2D.create(position,position+velocity*delta,1)
	var hit = get_world_2d().direct_space_state.intersect_ray(q)
	if not hit.is_empty():
		position = hit.position+hit.normal*3
		velocity = velocity.bounce(hit.normal)*0.45
	else: position += velocity*delta
	velocity *= exp(-delta*1.3)
	fuse -= delta
	if fuse <= 0:
		for a in game.actors:
			var distance = a.position.distance_to(position)
			if a.alive and distance < 155:
				var cover = PhysicsRayQueryParameters2D.create(position,a.position,1)
				if get_world_2d().direct_space_state.intersect_ray(cover).is_empty(): a.damage(110*(1-distance/175),shooter)
		for o in game.obstacles:
			if is_instance_valid(o) and position.distance_to(o.position)<140: o.damage(100,shooter)
		game.effects.burst(position,"wood",35)
		game.effects.burst(position,"smoke",20)
		game.effects.ring(position,155,Color("e8b777"))
		game.audio.play("grenade",position,0)
		game.shake = maxf(game.shake,8*maxf(0,1-game.player.position.distance_to(position)/900))
		queue_free()
	queue_redraw()
func _draw():
	draw_circle(Vector2(3,4),9,Color(0,0,0,0.3))
	Art.icon(self,"grenade",Vector2.ZERO,0.65)
	draw_arc(Vector2.ZERO,14,-PI/2,-PI/2+TAU*(fuse/1.5),24,Color("d7b479"),1.5,true)
