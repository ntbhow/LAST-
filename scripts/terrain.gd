extends Node2D
var game
const SIZE = 3200
var buildings = [Rect2(450,440,380,300),Rect2(1040,460,300,250),Rect2(2160,520,520,350),Rect2(2230,2160,400,340),Rect2(500,2180,340,280)]
var areas = [[Vector2(660,380),"01 / RELAY"],[Vector2(2390,450),"02 / FREIGHT"],[Vector2(630,2110),"03 / BARRACKS"],[Vector2(2410,2090),"04 / WORKS"],[Vector2(520,1300),"PINE RIDGE"]]

func _draw():
	var rng = RandomNumberGenerator.new()
	rng.seed = 44120
	draw_rect(Rect2(0,0,SIZE,SIZE),Color("647052"))
	for i in 4400:
		var p = Vector2(rng.randf_range(0,SIZE),rng.randf_range(0,SIZE))
		if i%3 == 0:
			draw_circle(p,rng.randf_range(2,12),Color(0.28,0.34,0.21,0.13))
		else:
			draw_line(p,p+Vector2(rng.randf_range(2,7),rng.randf_range(-3,3)),Color(0.77,0.76,0.49,0.20),1)
	# Crossroads, shoulders, broken center lines and tire tracks.
	for r in [Rect2(0,1450,SIZE,230),Rect2(1490,0,210,SIZE)]:
		draw_rect(r.grow(22),Color("8c8969"))
		draw_rect(r,Color("686c60"))
		draw_rect(r.grow(-7),Color("5d635a"))
	for i in range(0,SIZE,76):
		draw_line(Vector2(i,1565),Vector2(i+30,1565),Color("bcb998"),3)
		draw_line(Vector2(1595,i),Vector2(1595,i+30),Color("bcb998"),3)
	for i in 900:
		var p = Vector2(rng.randf_range(0,SIZE),rng.randf_range(1460,1670))
		draw_line(p,p+Vector2(rng.randf_range(2,10),0),Color(0.3,0.33,0.29,0.3),1)
	for r in buildings:
		draw_rect(r.grow(35),Color("898a71"))
		draw_rect(r,Color("424c43"))
		draw_rect(r.grow(-12),Color("a29c80"))
		for y in range(int(r.position.y)+18,int(r.end.y)-10,22):
			draw_line(Vector2(r.position.x+10,y),Vector2(r.end.x-10,y),Color("8b876f"),1)
		for x in range(int(r.position.x)+16,int(r.end.x)-10,44):
			draw_line(Vector2(x,r.position.y+12),Vector2(x,r.end.y-12),Color(0.4,0.4,0.32,0.15),1)
		# Door walkway.
		draw_rect(Rect2(r.get_center().x-35,r.end.y,70,44),Color("b0a68a"))
	for a in areas:
		draw_string(ThemeDB.fallback_font,a[0],a[1],HORIZONTAL_ALIGNMENT_CENTER,-1,24,Color(0.8,0.8,0.63,0.4))
	for i in range(0,SIZE,64):
		draw_line(Vector2(i,0),Vector2(i+30,0),Color("a2a280"),7)
		draw_line(Vector2(i,SIZE),Vector2(i+30,SIZE),Color("a2a280"),7)
