extends Node2D
var game
var alpha: Array[float] = [1.0,1.0,1.0,1.0,1.0]
func _process(delta):
	if game.player == null: return
	var changed = false
	for i in game.terrain.buildings.size():
		var r: Rect2 = game.terrain.buildings[i]
		var goal = 0.06 if r.grow(30).has_point(game.player.position) else 0.94
		var next = move_toward(alpha[i],goal,delta*5)
		changed = changed or next != alpha[i]
		alpha[i] = next
	if changed: queue_redraw()
func _draw():
	for i in game.terrain.buildings.size():
		var r: Rect2 = game.terrain.buildings[i]
		draw_rect(Rect2(r.position+Vector2(9,13),r.size),Color(0.06,0.08,0.06,alpha[i]*0.3))
		draw_rect(r,Color(0.28,0.34,0.3,alpha[i]))
		draw_rect(r.grow(-7),Color(0.40,0.46,0.40,alpha[i]))
		for y in range(int(r.position.y)+15,int(r.end.y)-8,14):
			draw_line(Vector2(r.position.x+8,y),Vector2(r.end.x-8,y),Color(0.21,0.29,0.25,alpha[i]*0.6),2)
		draw_line(Vector2(r.get_center().x,r.position.y),Vector2(r.get_center().x,r.end.y),Color(0.64,0.65,0.52,alpha[i]),5)
		draw_rect(Rect2(r.position+Vector2(25,25),Vector2(45,32)),Color(0.24,0.29,0.25,alpha[i]))
		draw_string(ThemeDB.fallback_font,r.position+Vector2(26,90),"D / 0"+str(i+1),HORIZONTAL_ALIGNMENT_LEFT,-1,26,Color(0.75,0.74,0.59,alpha[i]*0.6))
