extends Node2D
var game
var center = Vector2(1600,1600)
var radius = 2250.0
var next_center = Vector2(1600,1600)
var next_radius = 1430.0
var from_center = Vector2(1600,1600)
var from_radius = 2250.0
var stage = 0
var clock = 0.0
var holding = true
var hold_times = [50.0,40.0,35.0,30.0,25.0,20.0,10.0]
var shrink_times = [35.0,35.0,35.0,30.0,30.0,25.0,20.0]
var radii = [1430.0,1080.0,750.0,470.0,250.0,90.0,0.0]
var damage_rates = [1.0,2.0,3.0,5.0,8.0,12.0,24.0]

func remaining() -> float:
	return maxf(0,(hold_times[stage] if holding else shrink_times[stage])-clock)

func _physics_process(delta):
	if game.state != "playing": return
	clock += delta
	if holding and clock >= hold_times[stage]:
		holding = false
		clock = 0
		from_center = center
		from_radius = radius
		game.audio.play("zone",game.player.position,-5)
	if not holding:
		var t = clampf(clock/shrink_times[stage],0,1)
		center = from_center.lerp(next_center,t)
		radius = lerpf(from_radius,next_radius,t)
		if t >= 1 and stage < radii.size()-1:
			stage += 1
			clock = 0
			holding = true
			next_radius = radii[stage]
			var shift = Vector2.from_angle(game.rng.randf()*TAU)*maxf(0,radius-next_radius)*0.55
			next_center = center+shift
	for a in game.actors:
		if a.alive and a.position.distance_to(center) > radius:
			a.damage(damage_rates[stage]*delta,null,true)
	queue_redraw()

func _draw():
	for i in 96:
		var a = Vector2.from_angle(i*TAU/96)
		var b = Vector2.from_angle((i+1)*TAU/96)
		draw_colored_polygon(PackedVector2Array([center+a*radius,center+b*radius,center+b*6000,center+a*6000]),Color(0.46,0.15,0.09,0.17))
	draw_arc(center,radius,0,TAU,180,Color("dc9977"),4,true)
	for i in 96:
		draw_arc(next_center,next_radius,i*TAU/96,(i+0.55)*TAU/96,3,Color(0.9,0.88,0.68,0.7),2,true)
