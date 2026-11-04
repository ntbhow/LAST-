extends StaticBody2D
const Art = preload("res://scripts/art.gd")
var game
var kind = "wall"
var dims = Vector2(60,60)
var hp = 100.0
var max_hp = 100.0
var broken = false
var flash = 0.0
var variant = 0

func setup(g, type_: String, pos: Vector2, size_: Vector2):
	game = g
	kind = type_
	position = pos
	dims = size_
	variant = int(pos.x + pos.y) % 7
	hp = 65 if kind == "wood" else 110
	max_hp = hp
	collision_layer = 1
	collision_mask = 0
	var shape = CollisionShape2D.new()
	if kind in ["tree","rock"]:
		var s = CircleShape2D.new()
		s.radius = dims.x * 0.38
		shape.shape = s
	else:
		var s = RectangleShape2D.new()
		s.size = dims
		shape.shape = s
	add_child(shape)
	z_index = 3 if kind == "tree" else 1

func damage(amount: float, source = null):
	if broken: return
	flash = 0.12
	if kind in ["wood","supply"]:
		hp -= amount
		if hp <= 0:
			broken = true
			collision_layer = 0
			game.break_crate(self, source)
			queue_free()
	queue_redraw()

func _process(delta):
	if flash > 0:
		flash -= delta
		queue_redraw()

func _draw():
	var r = Rect2(-dims/2,dims)
	if kind == "tree":
		var rng = RandomNumberGenerator.new()
		rng.seed = variant * 99 + 2
		draw_circle(Vector2(15,17),dims.x*0.8,Color(0.04,0.07,0.04,0.25))
		draw_circle(Vector2.ZERO,dims.x*0.3,Color("5c513b"))
		for i in 16:
			var p = Vector2.from_angle(i*2.4)*rng.randf_range(0,dims.x*0.5)
			var color = Color("3e573e").lightened(rng.randf_range(0,0.2))
			draw_circle(p+Vector2(3,5),dims.x*0.33,Color("2c3e2d"))
			draw_circle(p,dims.x*0.30,color)
			draw_arc(p,dims.x*0.24,3.4,5.7,8,color.lightened(0.12),2,true)
	elif kind == "rock":
		var pts = PackedVector2Array()
		for i in 8: pts.append(Vector2.from_angle(i*TAU/8)*dims.x*(0.39+sin(i*3+variant)*0.06))
		draw_set_transform(Vector2(7,9))
		draw_colored_polygon(pts,Color(0.04,0.06,0.04,0.3))
		draw_set_transform(Vector2.ZERO)
		draw_colored_polygon(pts,Color("697267"))
		Art.poly(self,[pts[0],pts[1],pts[3],Vector2(-8,-8)],Color("81877a"))
		Art.poly(self,[pts[4],pts[5],pts[6],Vector2(-8,-8)],Color("929687"))
		draw_line(pts[6],pts[0],Color("a0a28f"),2,true)
	else:
		draw_style_box(Art.box(Color(0.03,0.05,0.03,0.28),3),Rect2(r.position+Vector2(6,8),dims+Vector2(3,3)))
		var base = Color("646b60") if kind == "wall" else (Color("987c50") if kind == "wood" else Color("596758"))
		if flash > 0: base = base.lightened(0.4)
		draw_rect(r,Color("29352e"))
		draw_rect(r.grow(-3),base)
		draw_line(r.position+Vector2(3,3),r.position+Vector2(dims.x-3,3),base.lightened(0.35),2)
		if kind == "wood":
			for x in range(8,int(dims.x)-4,10):
				draw_line(r.position+Vector2(x,3),r.position+Vector2(x,dims.y-3),Color("67583c"),1)
				draw_line(r.position+Vector2(x+3,8),r.position+Vector2(x+3,dims.y-8),Color("aa8d5c"),1)
			draw_line(r.position+Vector2(6,6),r.end-Vector2(6,6),Color("c0a270"),7)
			draw_line(Vector2(r.end.x-6,r.position.y+6),Vector2(r.position.x+6,r.end.y-6),Color("b39663"),6)
		elif kind == "supply":
			for x in [-dims.x*0.3,dims.x*0.3]:
				draw_rect(Rect2(x-3,-dims.y/2,6,dims.y),Color("a0a68a"))
			draw_rect(Rect2(-10,-7,20,14),Color("d3c798"))
			draw_line(Vector2(-6,0),Vector2(6,0),Color("5d664e"),3)
		else:
			for x in range(15,int(dims.x),32): draw_line(r.position+Vector2(x,3),r.position+Vector2(x,dims.y-3),base.darkened(0.2),1)
		if kind in ["wood","supply"]:
			for p in [r.position+Vector2(6,6),r.end-Vector2(6,6),Vector2(r.position.x+6,r.end.y-6),Vector2(r.end.x-6,r.position.y+6)]: draw_circle(p,1.5,Color("303c32"))
			if hp < max_hp:
				draw_line(Vector2(-12,-15),Vector2(1,2),Color("3e3528"),2)
				draw_line(Vector2(1,2),Vector2(-6,14),Color("3e3528"),2)
				draw_rect(Rect2(-dims.x/2,-dims.y/2-8,dims.x*hp/max_hp,3),Color("d5b878"))
