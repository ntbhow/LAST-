extends Node2D
var particles: Array = []
var rings: Array = []

func burst(pos: Vector2, kind: String, count: int, angle: float = 0):
	for i in count:
		if particles.size() >= 600: break
		var color = Color("d2c29c")
		var speed = randf_range(40,170)
		var life = randf_range(0.15,0.42)
		var dir = Vector2.from_angle(randf()*TAU)
		if kind == "hit": color = Color("c38b71")
		if kind == "wood": color = Color("c9a06b")
		if kind == "metal": color = Color("f2d399")
		if kind == "casing":
			color = Color("ddba71")
			dir = Vector2.from_angle(angle+1.4+randf()*0.4)
			life = 0.6
		if kind == "smoke":
			color = Color(0.8,0.78,0.66,0.3)
			speed = 25
		particles.append({"pos":pos,"vel":dir*speed,"life":life,"max":life,"color":color,"size":randf_range(1.3,3.5),"kind":kind})

func ring(pos: Vector2, radius: float, color: Color): rings.append({"pos":pos,"radius":radius,"life":0.4,"color":color})

func _process(delta):
	for i in range(particles.size()-1,-1,-1):
		var p = particles[i]
		p.life -= delta
		if p.life <= 0: particles.remove_at(i); continue
		p.pos += p.vel*delta
		p.vel *= exp(-delta*5)
	for i in range(rings.size()-1,-1,-1):
		rings[i].life -= delta
		if rings[i].life <= 0: rings.remove_at(i)
	queue_redraw()

func _draw():
	for p in particles:
		var col: Color = p.color
		col.a *= p.life / p.max
		if p.kind == "smoke": draw_circle(p.pos,p.size*3,col)
		else: draw_line(p.pos,p.pos+p.vel.normalized()*p.size,col,p.size,true)
	for r in rings:
		var col: Color = r.color
		col.a *= r.life/0.4
		draw_arc(r.pos,r.radius*(1-r.life/0.6),0,TAU,48,col,3,true)
