extends Node2D
const Art = preload("res://scripts/art.gd")
var actor
var fall = 0.0
func _process(delta):
	if is_instance_valid(actor.game.camera):
		visible = actor.position.distance_squared_to(actor.game.camera.position)<1100000
		if not visible: return
	fall = move_toward(fall,0.0 if actor.alive else 1.0,delta*4)
	rotation = actor.aim_angle+actor.weapon.recoil+fall*0.7
	scale = Vector2(1,1-fall*0.25)
	queue_redraw()
	if fall>=1: set_process(false)
func _draw():
	var a = actor
	var reloading = 0.0
	if a.weapon.reload_left>0: reloading = 1.0-a.weapon.reload_left/a.inv.stats().get("reload",1)
	Art.actor(self,a.suit,0,a.weapon.kick,reloading,a.use_left/a.use_total if a.use_total>0 else 0,a.weapon.melee_left/0.28,a.inv.helmet,a.inv.armor,a.inv.backpack,a.inv.gun().get("id",""),not a.alive)
	if a.weapon.muzzle_flash>0 and a.alive:
		var m: float = a.muzzle_distance()
		Art.poly(self,[Vector2(m-3,-3),Vector2(m+10,-8),Vector2(m+6,-2),Vector2(m+20,0),Vector2(m+6,3),Vector2(m+10,8),Vector2(m-3,3)],Color("ffe1a1"))
