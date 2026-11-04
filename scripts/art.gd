extends RefCounted
const Catalog = preload("res://scripts/catalog.gd")
const INK = Color("202925")

static func poly(c: CanvasItem, points: Array, color: Color):
	c.draw_colored_polygon(PackedVector2Array(points), color)

static func gun(c: CanvasItem, id: String, origin: Vector2, factor: float = 1.0):
	c.draw_set_transform(origin, 0, Vector2.ONE * factor)
	var long_ = id in ["rifle", "dmr", "shotgun"]
	var length_ = 40 if long_ else (28 if id == "smg" else 20)
	var accent = Catalog.tint(id)
	poly(c, [Vector2(-10,-5),Vector2(5,-5),Vector2(7,5),Vector2(-10,5),Vector2(-15,8),Vector2(-15,-8)], INK)
	c.draw_rect(Rect2(-7,-4,length_-3,8), Color("4c5550"))
	c.draw_rect(Rect2(1,-4,12,3), accent.darkened(0.2))
	c.draw_rect(Rect2(length_-11,-2,17,4), Color("1c2424"))
	c.draw_rect(Rect2(0,3,7,6), Color("3a423a"))
	c.draw_line(Vector2(0,-4),Vector2(length_-7,-4),Color("8f9890"),1)
	for x in range(13,length_-10,4): c.draw_line(Vector2(x,-3),Vector2(x,3),INK,1)
	if id == "dmr":
		c.draw_rect(Rect2(3,-3,16,6),Color("1b2628"))
		c.draw_circle(Vector2(18,0),3,Color("9cb7bf"))
	if id == "shotgun": c.draw_rect(Rect2(14,-5,13,10), Color("9d7953"))
	c.draw_set_transform(Vector2.ZERO)

static func actor(c: CanvasItem, suit: int, stride: float, kick: float, reload_progress: float, use_progress: float, melee: float, helmet: bool, armor: float, pack: bool, weapon: String, dead: bool = false):
	var cloth: Color = Catalog.SUITS[suit % 3]
	if dead: cloth = cloth.darkened(0.35)
	c.draw_set_transform(Vector2(4,6))
	c.draw_circle(Vector2.ZERO,22,Color(0.03,0.05,0.03,0.23))
	c.draw_set_transform(Vector2.ZERO)
	if pack:
		c.draw_style_box(box(Color("3b493c"),5), Rect2(-22,-13,14,26))
		c.draw_rect(Rect2(-22,-7,5,14), cloth.darkened(0.2))
		c.draw_line(Vector2(-19,-11),Vector2(-19,11),Color("a2946c"),2)
	poly(c,[Vector2(-13,-16),Vector2(3,-18),Vector2(12,-10),Vector2(12,10),Vector2(3,18),Vector2(-13,16),Vector2(-17,7),Vector2(-17,-7)],INK)
	poly(c,[Vector2(-11,-14),Vector2(3,-15),Vector2(10,-8),Vector2(10,8),Vector2(3,15),Vector2(-11,14)],cloth)
	c.draw_rect(Rect2(-10,-10,12,20),Color("4c5545") if armor <= 0 else Color("566162"))
	for y in [-7,0,7]:
		c.draw_line(Vector2(-9,y),Vector2(1,y),Color("92957a"),2)
	var hand = Vector2(18-kick*7,11)
	if reload_progress > 0: hand = hand.lerp(Vector2(1,14), sin(reload_progress*PI))
	if use_progress > 0: hand = Vector2(7+sin(use_progress*18)*2,3)
	if melee > 0: hand = Vector2(28,6).rotated(-sin(melee*PI)*1.7)
	c.draw_line(Vector2(0,13),hand,INK,12,true)
	c.draw_line(Vector2(0,13),hand,cloth.lightened(0.1),8,true)
	c.draw_circle(hand,4,Color("b8a084"))
	c.draw_line(Vector2(1,-13),Vector2(22-kick*7,-6),INK,11,true)
	c.draw_line(Vector2(1,-13),Vector2(22-kick*7,-6),cloth,7,true)
	if weapon != "": gun(c,weapon,Vector2(21-kick*7,0))
	else:
		c.draw_line(hand,hand+Vector2(15,0).rotated(-melee*2),Color("bfc3ae"),4,true)
	c.draw_circle(Vector2(-2,0),10,INK)
	c.draw_circle(Vector2(-2,-1),8.5,Color("b5a28a") if not helmet else cloth.lightened(0.12))
	if helmet:
		c.draw_arc(Vector2(-2,-1),7,-2.5,1.8,16,cloth.lightened(0.3),2,true)
		c.draw_rect(Rect2(3,-5,4,8),Color("29352f"))
	else: c.draw_arc(Vector2(-2,-1),7,1.6,4.8,12,Color("4e4b3c"),4,true)
	c.draw_line(Vector2(-6,-5),Vector2(-3,-6),Color("d4d2ac"),2)

static func box(color: Color, radius: int = 0) -> StyleBoxFlat:
	var s = StyleBoxFlat.new()
	s.bg_color = color
	s.set_corner_radius_all(radius)
	return s

static func icon(c: CanvasItem, id: String, pos: Vector2, scale_: float = 1.0):
	if Catalog.weapons.has(id):
		gun(c,id,pos,scale_)
		return
	c.draw_set_transform(pos,0,Vector2.ONE*scale_)
	var tint = Catalog.tint(id)
	if id.begins_with("ammo"):
		for x in [-7,0,7]:
			c.draw_rect(Rect2(x-2,-5,4,14),Color("b7a475"))
			poly(c,[Vector2(x-2,-5),Vector2(x,-10),Vector2(x+2,-5)],Color("ded3ab"))
	elif id.begins_with("armor"):
		poly(c,[Vector2(-7,-12),Vector2(-3,-12),Vector2(-3,-6),Vector2(3,-6),Vector2(3,-12),Vector2(7,-12),Vector2(11,7),Vector2(6,12),Vector2(-6,12),Vector2(-11,7)],tint)
		c.draw_rect(Rect2(-6,-2,12,10),Color("56656c"))
	elif id == "helmet":
		c.draw_arc(Vector2(0,3),10,PI,TAU,16,tint,7,true)
		c.draw_line(Vector2(-11,4),Vector2(11,4),tint,3)
	elif id == "backpack":
		c.draw_style_box(box(Color("788565"),4),Rect2(-9,-11,18,24))
		c.draw_rect(Rect2(-6,2,12,7),Color("424f41"))
		c.draw_line(Vector2(-4,-12),Vector2(4,-12),tint,3)
	elif id == "grenade":
		poly(c,[Vector2(-6,-7),Vector2(6,-7),Vector2(9,1),Vector2(6,11),Vector2(-6,11),Vector2(-9,1)],Color("78835b"))
		c.draw_line(Vector2(0,-12),Vector2(7,-8),tint,3)
		for y in [-3,3,8]: c.draw_line(Vector2(-5,y),Vector2(5,y),INK,1)
	else:
		c.draw_style_box(box(Color("ccd0b9"),2),Rect2(-11,-9,22,18))
		c.draw_rect(Rect2(-7,-9,3,18),Color("8d9a7d"))
		c.draw_rect(Rect2(2,-5,3,10),Color("a06d54"))
		c.draw_rect(Rect2(-1,-2,9,3),Color("a06d54"))
	c.draw_set_transform(Vector2.ZERO)
