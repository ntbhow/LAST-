extends Node2D
const Art = preload("res://scripts/art.gd")
const Catalog = preload("res://scripts/catalog.gd")
var item: Dictionary
var taken = false
var age = 0.0

func _process(delta):
	age += delta
	if age < 0.4: queue_redraw()

func _draw():
	var color = Catalog.tint(item.id)
	draw_circle(Vector2(2,5),22,Color(0.04,0.07,0.04,0.2))
	draw_arc(Vector2.ZERO,24,0.2,PI-0.2,18,Color(color,0.45),1.4,true)
	draw_arc(Vector2.ZERO,24,PI+0.2,TAU-0.2,18,Color(color,0.45),1.4,true)
	Art.icon(self,item.id,Vector2.ZERO,0.8)
	if item.count > 1: draw_string(ThemeDB.fallback_font,Vector2(12,18),str(item.count),HORIZONTAL_ALIGNMENT_LEFT,-1,11,Color("e0dfc8"))
