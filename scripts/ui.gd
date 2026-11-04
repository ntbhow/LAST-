extends Control
const Art = preload("res://scripts/art.gd")
const Catalog = preload("res://scripts/catalog.gd")
var game
var page = "menu"
var elements: Control
var inventory_open = false
var map_open = false
var settings_return = "menu"
var accent = Color("d8b879")
var muted = Color("9aa693")
var white = Color("e4e6d6")
var font: Font
var pulse = 0.0

func _ready():
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	font = ThemeDB.fallback_font
	process_mode = Node.PROCESS_MODE_ALWAYS

func reset(next_page: String):
	page = next_page
	if is_instance_valid(elements):
		remove_child(elements)
		elements.queue_free()
	elements = Control.new()
	elements.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(elements)
	queue_redraw()

func panel(rect: Rect2, color: Color = Color("19231f"), edge: bool = true):
	draw_style_box(Art.box(color,3),rect)
	if edge: draw_rect(rect,Color("465246"),false,1)

func text_at(pos: Vector2, text: String, size_: int = 16, color: Color = Color("e4e6d6")):
	draw_string(font,pos,text,HORIZONTAL_ALIGNMENT_LEFT,-1,size_,color)

func button(label_: String, rect: Rect2, action: Callable, primary: bool = false, tip: String = "") -> Button:
	var b = Button.new()
	b.text = label_
	b.position = rect.position
	b.size = rect.size
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.tooltip_text = tip
	b.add_theme_font_size_override("font_size",18)
	for kind in ["normal","hover","pressed","focus"]:
		var s = StyleBoxFlat.new()
		s.bg_color = accent if primary else Color("26322b")
		if kind == "hover": s.bg_color = s.bg_color.lightened(0.14)
		if kind == "pressed": s.bg_color = s.bg_color.darkened(0.15)
		s.border_color = accent if primary else Color("5e6d58")
		s.set_border_width_all(1)
		s.set_corner_radius_all(2)
		b.add_theme_stylebox_override(kind,s)
	b.add_theme_color_override("font_color",Color("202a22") if primary else white)
	b.add_theme_color_override("font_hover_color",Color("202a22") if primary else white)
	b.pressed.connect(action)
	b.mouse_entered.connect(func():
		var tween = b.create_tween()
		tween.tween_property(b,"modulate",Color(1.12,1.12,1.08),0.10))
	b.mouse_exited.connect(func():
		var tween = b.create_tween()
		tween.tween_property(b,"modulate",Color.WHITE,0.1))
	elements.add_child(b)
	return b

func show_menu():
	game.state = "menu"
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	reset("menu")
	inventory_open = false
	map_open = false
	button("DEPLOY",Rect2(80,358,310,58),func(): game.start_match(),true)
	button("CUSTOMIZE",Rect2(80,430,310,48),show_customize)
	button("SETTINGS",Rect2(80,490,310,48),func(): settings_return="menu"; show_settings())
	button("QUIT",Rect2(80,550,310,48),func(): get_tree().quit())

func show_customize():
	reset("customize")
	for i in 3:
		var index = i
		button(["01  /  RANGER","02  /  SAND","03  /  SLATE"][i],Rect2(80+i*208,480,192,50),func(): game.settings.values.suit=index; game.settings.save(); show_customize(),game.settings.values.suit == i)
	button("BACK",Rect2(80,590,190,48),show_menu)

func show_settings():
	reset("settings")
	var rows = [["Master volume","master",0.0,1.0,0.05],["Music","music",0.0,1.0,0.05],["Sound effects","sfx",0.0,1.0,0.05],["Aim sensitivity","sensitivity",0.4,2.0,0.05],["Screen shake","shake",0.0,1.0,0.05],["HUD scale","ui_scale",0.85,1.15,0.05]]
	for i in rows.size():
		var row = rows[i]
		var label_ = Label.new()
		label_.text = row[0]
		label_.position = Vector2(110,177+i*49)
		label_.add_theme_font_size_override("font_size",18)
		elements.add_child(label_)
		var slider = HSlider.new()
		slider.position = Vector2(370,184+i*49)
		slider.size = Vector2(320,24)
		slider.min_value = row[2]
		slider.max_value = row[3]
		slider.step = row[4]
		slider.value = game.settings.values[row[1]]
		var key: String = row[1]
		slider.value_changed.connect(func(v): game.settings.values[key]=v; game.settings.save())
		elements.add_child(slider)
	button("FULLSCREEN: "+("ON" if game.settings.values.fullscreen else "OFF"),Rect2(110,493,275,44),func(): game.settings.values.fullscreen=not game.settings.values.fullscreen; game.settings.save(); show_settings())
	button("BOTS: "+("VETERAN" if game.settings.values.difficulty == 1 else "REGULAR"),Rect2(405,493,285,44),func(): game.settings.values.difficulty=1-int(game.settings.values.difficulty); game.settings.save(); show_settings())
	button("SAVE & BACK",Rect2(110,574,235,48),func(): game.settings.save(); show_pause() if settings_return=="paused" else show_menu(),true)

func show_hud():
	reset("hud")
	if inventory_open: make_inventory_buttons()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if inventory_open or map_open or game.autoplay else Input.MOUSE_MODE_CAPTURED

func toggle_inventory():
	inventory_open = not inventory_open
	map_open = false
	show_hud()

func show_pause():
	game.state = "paused"
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	reset("pause")
	button("RESUME",Rect2(490,280,300,54),resume,true)
	button("SETTINGS",Rect2(490,348,300,48),func(): settings_return="paused"; show_settings())
	button("REDEPLOY",Rect2(490,410,300,48),func(): game.start_match())
	button("MAIN MENU",Rect2(490,472,300,48),show_menu)

func resume():
	get_tree().paused = false
	game.state = "playing"
	inventory_open = false
	map_open = false
	show_hud()

func show_result():
	reset("result")
	button("DEPLOY AGAIN",Rect2(444,522,392,56),func(): game.start_match(),true)
	button("MAIN MENU",Rect2(444,592,392,44),show_menu)

func make_inventory_buttons():
	for i in 2:
		var slot = i
		button("EQUIP",Rect2(390,230+i*108,95,32),func(): game.player.weapon.switch(slot); show_hud(),false,"Select weapon slot "+str(i+1))
		button("DROP",Rect2(495,230+i*108,88,32),func(): game.player.weapon.cancel_reload(); game.spawn_loot(game.player.inv.drop_gun(slot),game.player.position+Vector2(45,0)); show_hud())
	var ids = ["bandage","medkit","grenade"]
	for i in 3:
		var id: String = ids[i]
		button("USE" if id != "grenade" else "THROW",Rect2(685+i*145,282,116,32),func():
			if id=="grenade": game.player.throw_grenade()
			else: game.player.use_item(id)
			show_hud())
		button("DROP",Rect2(685+i*145,322,116,30),func(): game.spawn_loot(game.player.inv.drop_supply(id),game.player.position+Vector2(40,0)); show_hud())
	for i in 3:
		var kind: String = ["light","heavy","shell"][i]
		button("DROP 10",Rect2(685+i*145,416,116,30),func():
			var n = mini(10,game.player.inv.ammo[kind])
			if n>0:
				game.player.inv.ammo[kind]-=n
				game.spawn_loot({"id":"ammo_"+kind,"count":n},game.player.position+Vector2(40,0))
			show_hud())
	for i in 3:
		var equipment: String = ["armor","helmet","backpack"][i]
		button("DROP",Rect2(495,447+i*30,88,26),func(): game.spawn_loot(game.player.inv.drop_equipment(equipment),game.player.position+Vector2(45,0)); show_hud(),false,"Pack can be dropped when load is 120 or less.")
	button("CLOSE  /  TAB",Rect2(858,560,260,42),func(): inventory_open=false; show_hud(),true)

func _process(delta):
	pulse += delta
	if page == "hud": queue_redraw()

func _draw():
	if font == null: font = ThemeDB.fallback_font
	if page in ["menu","customize","settings"]:
		draw_menu_background()
		if page == "menu":
			text_at(Vector2(80,108),"D / 01     OFFLINE OPERATIONS",15,accent)
			text_at(Vector2(74,211),"DUSTLINE",82,white)
			draw_line(Vector2(80,239),Vector2(390,239),accent,2)
			text_at(Vector2(80,280),"LAST SCOUT STANDING",22)
			text_at(Vector2(80,312),"Solo battle royale / Sector 07",16,muted)
			text_at(Vector2(80,663),"SOLO  /  20 BOTS  /  NO CONNECTION REQUIRED",13,muted)
			text_at(Vector2(920,663),"FIELD BUILD   0.1",13,accent)
		elif page == "customize":
			text_at(Vector2(80,105),"OPERATOR / APPEARANCE",32)
			text_at(Vector2(80,145),"Cosmetic only. Same equipment, same rules.",17,muted)
			for i in 3:
				panel(Rect2(80+i*208,190,192,270),Color("29382e"))
				if int(game.settings.values.suit)==i: draw_rect(Rect2(80+i*208,190,192,270),accent,false,2)
				portrait(Vector2(176+i*208,320),i,3.0)
				text_at(Vector2(108+i*208,435),["WOODLAND","DUST / CANVAS","COAST / SLATE"][i],14,accent)
		elif page == "settings":
			panel(Rect2(80,70,650,580),Color("18231f"))
			text_at(Vector2(110,125),"FIELD SETTINGS",30)
			text_at(Vector2(800,190),"CONTROLS",25,accent)
			var lines = ["WASD   Move    /    Shift   Run","Mouse   Aim    /    LMB   Fire","R   Reload    /    E   Pick up","1 / 2   Weapons    /    3   Knife","H   Bandage    /    J   Medkit","G   Grenade    /    X   Cancel heal","Q / Wheel   Select nearby loot","Tab   Inventory    /    M   Map","Esc   Pause    /    F3   Debug"]
			for i in lines.size(): text_at(Vector2(800,235+i*35),lines[i],16,white)
	elif page == "hud":
		draw_hud()
		if inventory_open: draw_inventory()
		if map_open: draw_large_map()
	elif page == "pause":
		draw_rect(Rect2(Vector2.ZERO,size),Color(0.06,0.09,0.07,0.88))
		text_at(Vector2(490,196),"OPERATION PAUSED",28)
		text_at(Vector2(490,235),"Offline simulation is suspended.",17,muted)
	elif page == "result": draw_result()

func draw_menu_background():
	draw_rect(Rect2(Vector2.ZERO,size),Color("14201b"))
	# A designed vector field illustration: contour lines, roads, depot and scout.
	for i in 20:
		var points = PackedVector2Array()
		for j in 35:
			var x = 510+j*24
			points.append(Vector2(x,45+i*38+sin(j*0.24+i*0.4)*25))
		draw_polyline(points,Color(0.40,0.47,0.34,0.14),1,true)
	Art.poly(self,[Vector2(650,720),Vector2(1180,0),Vector2(1250,0),Vector2(720,720)],Color("394435"))
	for i in 10:
		var p = Vector2(690,700)+Vector2(0.59,-0.81)*i*90
		draw_line(p,p+Vector2(0.59,-0.81)*35,Color("6f775b"),3)
	for i in 5:
		var p = Vector2(735+i*90,210+sin(i*5)*140)
		draw_circle(p+Vector2(13,17),43,Color(0.02,0.06,0.03,0.25))
		for j in 6: draw_circle(p+Vector2.from_angle(j*2.4)*20,28,Color("344c36").lightened(j*0.018))
	panel(Rect2(940,355,205,147),Color("4b5a49"))
	for y in range(365,490,12): draw_line(Vector2(950,y),Vector2(1135,y),Color("344333"),2)
	draw_line(Vector2(1042,355),Vector2(1042,502),Color("8b9576"),5)
	draw_arc(Vector2(870,350),220,0,TAU,96,Color(0.71,0.70,0.51,0.25),1,true)
	draw_arc(Vector2(870,350),195,0.2,2.6,48,Color(0.71,0.70,0.51,0.15),2,true)
	portrait(Vector2(835,365),int(game.settings.values.suit),5.0)
	text_at(Vector2(769,572),"SCOUT / "+["RANGER","SAND","SLATE"][int(game.settings.values.suit)],14,accent)
	for i in 20: draw_rect(Rect2(480+i*7,0,8,720),Color(0.078,0.125,0.105,0.06*(20-i)/20.0))

func portrait(pos: Vector2, suit: int, factor: float):
	# Portrait is a separate illustration with the same kit / material palette.
	var cloth: Color = Catalog.SUITS[suit]
	draw_set_transform(pos,-0.34,Vector2.ONE*factor)
	draw_circle(Vector2(3,5),25,Color(0,0,0,0.2))
	for side in [-1,1]:
		draw_style_box(Art.box(Color("1c2922"),3),Rect2(-8,side*12-5,27,10))
		draw_style_box(Art.box(cloth.darkened(0.3),3),Rect2(-19,side*10-7,15,14))
	draw_style_box(Art.box(cloth.darkened(0.4),4),Rect2(-24,-16,16,32))
	draw_style_box(Art.box(cloth,7),Rect2(-16,-21,30,42))
	draw_rect(Rect2(-12,-15,15,30),Color("465547"))
	for y in [-10,-3,4,11]: draw_line(Vector2(-10,y),Vector2(1,y),cloth.lightened(0.2),2)
	draw_line(Vector2(5,-17),Vector2(31,-7),cloth.lightened(0.1),11,true)
	draw_line(Vector2(6,17),Vector2(28,6),cloth,11,true)
	draw_rect(Rect2(12,-5,34,10),Color("242c27"))
	draw_rect(Rect2(43,-2,17,4),Color("939a86"))
	draw_rect(Rect2(23,-5,14,3),accent)
	draw_circle(Vector2(-1,0),12,Color("233027"))
	draw_circle(Vector2(-2,-1),10,cloth.lightened(0.2))
	draw_arc(Vector2(-2,-1),8,2.5,5.5,18,cloth.lightened(0.45),2,true)
	draw_rect(Rect2(5,-6,5,12),Color("303e32"))
	draw_set_transform(Vector2.ZERO)

func draw_hud():
	var p = game.player
	if not is_instance_valid(p): return
	var w = size.x
	var h = size.y
	var scale_: float = game.settings.values.ui_scale
	draw_set_transform(Vector2(24,h-24),0,Vector2.ONE*scale_)
	panel(Rect2(0,-112,308,112),Color(0.08,0.12,0.09,0.94))
	text_at(Vector2(16,-85),"SCOUT  /  "+str(int(ceil(p.hp)))+" HP",15)
	text_at(Vector2(223,-85),str(p.kills)+" KILLS",13,accent)
	draw_rect(Rect2(16,-67,276,15),Color("344235"))
	draw_rect(Rect2(16,-67,276*p.hp/100,15),Color("acbb80") if p.hp>30 else Color("c77e60"))
	draw_rect(Rect2(16,-43,276,5),Color("35433e"))
	draw_rect(Rect2(16,-43,276*p.inv.armor/50,5),Color("9ab7be"))
	text_at(Vector2(16,-13),"ARMOR "+str(int(p.inv.armor))+"   /   "+("HELMET" if p.inv.helmet else "NO HELMET"),12,muted)
	draw_set_transform(Vector2.ZERO)
	# Weapon strip.
	var start_x = w/2-211
	for i in 3:
		var r = Rect2(start_x+i*144,h-91,136,67)
		panel(r,Color("28362d") if p.inv.active == i else Color(0.08,0.12,0.09,0.92))
		if p.inv.active == i: draw_rect(Rect2(r.position,Vector2(136,3)),accent)
		text_at(r.position+Vector2(9,18),str(i+1),13,accent)
		if i<2 and not p.inv.guns[i].is_empty():
			Art.icon(self,p.inv.guns[i].id,r.position+Vector2(63,30),0.9)
			text_at(r.position+Vector2(9,56),Catalog.weapons[p.inv.guns[i].id].short,12)
		elif i == 2:
			draw_line(r.position+Vector2(47,25),r.position+Vector2(86,25),Color("b9c1aa"),4,true)
			text_at(r.position+Vector2(9,56),"FIELD KNIFE",12)
		else: text_at(r.position+Vector2(35,42),"EMPTY",13,muted)
	var g: Dictionary = p.inv.gun()
	panel(Rect2(w-270,h-152,246,128),Color(0.08,0.12,0.09,0.94))
	text_at(Vector2(w-252,h-122),Catalog.weapons[g.id].name if not g.is_empty() else "FIELD KNIFE",15,accent)
	text_at(Vector2(w-254,h-72),str(g.rounds).pad_zeros(2) if not g.is_empty() else "--",44)
	text_at(Vector2(w-181,h-77),"/ "+str(p.inv.ammo[p.inv.stats().ammo]) if not g.is_empty() else "MELEE",17,muted)
	text_at(Vector2(w-252,h-43),"R  RELOAD" if p.weapon.reload_left<=0 else "RELOADING...",12,muted)
	# Quick consumables, center top status and feed.
	text_at(Vector2(28,h-151),"H  BANDAGE "+str(p.inv.supplies.bandage)+"     J  MEDKIT "+str(p.inv.supplies.medkit)+"     G  FRAG "+str(p.inv.supplies.grenade),13,white)
	panel(Rect2(w/2-168,20,336,56),Color(0.08,0.12,0.09,0.92))
	text_at(Vector2(w/2-150,43),"%02d ALIVE"%game.living(),17)
	text_at(Vector2(w/2+9,43),"PHASE 0"+str(game.zone.stage+1),14,accent)
	text_at(Vector2(w/2-150,64),("DUST MOVES IN " if game.zone.holding else "DUST CLOSING ")+format_time(game.zone.remaining()),12,muted)
	text_at(Vector2(26,35),"DUSTLINE  /  "+format_time(game.elapsed),14,accent)
	for i in game.feed.size():
		if game.feed[i].time>0: text_at(Vector2(26,64+i*24),game.feed[i].text,13,white)
	draw_map(Rect2(w-202,24,178,178),false)
	text_at(Vector2(w-198,221),"M  SECTOR MAP",12,muted)
	text_at(Vector2(w/2-200,h-109),"TAB  INVENTORY     M  MAP     ESC  PAUSE",12,muted)
	if p.position.distance_to(game.zone.center)>game.zone.radius:
		text_at(Vector2(w/2-118,103),"OUTSIDE SAFE ZONE",19,Color("e9aa83"))
	if p.use_left>0 or p.weapon.reload_left>0:
		var remain = p.use_left if p.use_left>0 else p.weapon.reload_left
		var total = p.use_total if p.use_left>0 else p.inv.stats().get("reload",1)
		panel(Rect2(w/2-100,h/2+70,200,41))
		text_at(Vector2(w/2-85,h/2+91),("HEALING  [X CANCEL]" if p.use_left>0 else "RELOADING"),12)
		draw_rect(Rect2(w/2-85,h/2+100,170*(1-remain/total),3),accent)
	if not inventory_open and not map_open:
		draw_reticle()
		var near = game.nearby_loot(p.position)
		if not near.is_empty():
			var l = near[game.loot_selection%near.size()]
			var pos: Vector2 = game.get_viewport().get_canvas_transform()*l.position
			pos += Vector2(35,38)
			pos = pos.clamp(Vector2(10,120),Vector2(w-310,h-190))
			panel(Rect2(pos,Vector2(290,62)),Color(0.09,0.14,0.10,0.94))
			text_at(pos+Vector2(12,24),"E  "+Catalog.title(l.item),14,Catalog.tint(l.item.id))
			var detail = "Q / WHEEL  "+str(game.loot_selection%near.size()+1)+" OF "+str(near.size())
			if l.item.id.begins_with("armor"): detail += "   "+str(int(p.inv.armor))+" > "+l.item.id.trim_prefix("armor")
			text_at(pos+Vector2(12,47),detail,11,muted)
	if game.debug_enabled:
		panel(Rect2(25,180,295,100))
		text_at(Vector2(36,204),"FPS %d  /  %.2f ms"%[Engine.get_frames_per_second(),Performance.get_monitor(Performance.TIME_PROCESS)*1000],14)
		text_at(Vector2(36,227),"BOTS %d  SHOTS %d  LOOT %d"%[game.living()-(1 if p.alive else 0),game.projectiles.live_count,game.loots.size()],13)
		text_at(Vector2(36,251),"SEED "+str(game.match_seed),13,accent)
		text_at(Vector2(36,270),"RECOIL %.3f  SPREAD %.3f"%[p.weapon.recoil,p.weapon.spread()],12,muted)
	if game.elapsed<13:
		text_at(Vector2(w/2-215,136),"WASD MOVE   /   E LOOT   /   3 KNIFE   /   SHIFT RUN",13,white)

func draw_reticle():
	var pos: Vector2 = game.cursor
	var gap = 5+game.player.weapon.spread()*170
	var color = Color("f0e9c9")
	for d in [Vector2.UP,Vector2.DOWN,Vector2.LEFT,Vector2.RIGHT]:
		draw_line(pos+d*gap,pos+d*(gap+7),Color("16231b"),4,true)
		draw_line(pos+d*gap,pos+d*(gap+7),color,1.5,true)
	draw_circle(pos,1.5,color)
	# The small amber tick shows the recoiled barrel direction independently.
	var barrel: Vector2 = game.get_viewport().get_canvas_transform()*(game.player.position+Vector2.from_angle(game.player.aim_angle+game.player.weapon.recoil)*minf(500,game.player.position.distance_to(game.screen_to_world(pos))))
	draw_circle(barrel,2,accent)
	if game.hit_marker>0:
		for d in [Vector2(1,1),Vector2(-1,1),Vector2(1,-1),Vector2(-1,-1)]: draw_line(pos+d*6,pos+d*11,Color("e7b478"),2,true)

func draw_map(rect: Rect2, large: bool):
	panel(rect,Color("566247"))
	var k = rect.size.x/3200.0
	for r in [Rect2(0,1450,3200,230),Rect2(1490,0,210,3200)]: draw_rect(Rect2(rect.position+r.position*k,r.size*k),Color("858673"))
	for r in game.terrain.buildings: draw_rect(Rect2(rect.position+r.position*k,r.size*k),Color("c2bd98"))
	for o in game.obstacles:
		if not is_instance_valid(o): continue
		if o.kind == "tree": draw_circle(rect.position+o.position*k,2 if not large else 5,Color("344c32"))
	# Clip zone geometry to the map with sampled segments.
	for circle in [[game.zone.center,game.zone.radius,Color("e4a07c")],[game.zone.next_center,game.zone.next_radius,Color("e9e5bd")]]:
		for i in 120:
			var a: Vector2 = rect.position+(circle[0]+Vector2.from_angle(i*TAU/120)*circle[1])*k
			var b: Vector2 = rect.position+(circle[0]+Vector2.from_angle((i+1)*TAU/120)*circle[1])*k
			if rect.has_point(a) and rect.has_point(b): draw_line(a,b,circle[2],2,true)
	var pp: Vector2 = rect.position+game.player.position*k
	draw_circle(pp,5 if large else 3,Color("fff2be"))
	draw_line(pp,pp+Vector2.from_angle(game.player.aim_angle)*(15 if large else 8),Color("fff2be"),2,true)
	if large:
		for area in game.terrain.areas: text_at(rect.position+area[0]*k-Vector2(32,0),area[1],12,white)
	draw_rect(rect,Color("99a387"),false,1)

func draw_large_map():
	draw_rect(Rect2(Vector2.ZERO,size),Color(0.04,0.07,0.05,0.85))
	draw_map(Rect2(size.x/2-280,65,560,560),true)
	text_at(Vector2(size.x/2-280,44),"SECTOR 07 / TACTICAL MAP",19,accent)
	text_at(Vector2(size.x/2-280,657),"AMBER: DUST FRONT     IVORY: NEXT SAFE ZONE     M: CLOSE",13,white)
	text_at(Vector2(size.x/2-280,685),"Simulation continues while the map is open.",13,muted)

func draw_inventory():
	var inv = game.player.inv
	draw_rect(Rect2(Vector2.ZERO,size),Color(0.04,0.07,0.05,0.80))
	panel(Rect2(145,104,1000,520),Color("19261f"))
	text_at(Vector2(172,148),"FIELD INVENTORY",27)
	text_at(Vector2(700,146),"PACK  "+str(inv.used())+" / "+str(inv.capacity()),17,accent)
	text_at(Vector2(172,583),"Live inventory. Stay behind cover.",14,muted)
	for i in 2:
		panel(Rect2(172,178+i*108,440,97),Color("27352b"))
		text_at(Vector2(186,202+i*108),"0"+str(i+1),13,accent)
		if not inv.guns[i].is_empty():
			var g: Dictionary = inv.guns[i]
			Art.icon(self,g.id,Vector2(235,231+i*108),1.3)
			text_at(Vector2(283,207+i*108),Catalog.weapons[g.id].name,16)
			text_at(Vector2(283,230+i*108),str(g.rounds)+" LOADED  /  "+Catalog.weapons[g.id].ammo.to_upper(),12,muted)
		else: text_at(Vector2(240,219+i*108),"EMPTY WEAPON SLOT",15,muted)
	text_at(Vector2(186,423),"03   FIELD KNIFE",16,white)
	text_at(Vector2(186,465),"VEST  "+str(int(inv.armor))+" / 50",15,Catalog.tint("armor50"))
	text_at(Vector2(186,495),"HELMET  "+("EQUIPPED" if inv.helmet else "NONE"),14,muted)
	text_at(Vector2(186,525),"PACK  "+("EXTENDED" if inv.backpack else "STANDARD"),14,muted)
	for i in 3:
		var id: String = ["bandage","medkit","grenade"][i]
		panel(Rect2(675+i*145,178,136,182),Color("27352b"))
		Art.icon(self,id,Vector2(741+i*145,220),1.4)
		text_at(Vector2(689+i*145,257),id.to_upper()+"  "+str(inv.supplies[id]),13)
		var ammo: String = ["light","heavy","shell"][i]
		text_at(Vector2(687+i*145,392),ammo.to_upper()+"  "+str(inv.ammo[ammo]),14,accent)
	text_at(Vector2(685,489),"Bandage: +25 HP / 2s",14,muted)
	text_at(Vector2(685,514),"Medkit: full heal / 4s",14,muted)
	text_at(Vector2(685,539),"Damage interrupts healing and returns the item.",12,muted)

func draw_result():
	draw_rect(Rect2(Vector2.ZERO,size),Color(0.06,0.10,0.07,0.94))
	var win = game.rank == 1
	text_at(Vector2(444,115),"OPERATION / COMPLETE",16,accent)
	text_at(Vector2(435,231),"#%02d"%game.rank,100,white)
	text_at(Vector2(444,279),"LAST SCOUT STANDING" if win else "OPERATOR DOWN",27,accent)
	draw_line(Vector2(444,307),Vector2(836,307),Color("52634e"),1)
	var rows = [["ELIMINATIONS",str(game.player.kills)],["DAMAGE DEALT",str(int(game.player.damage_dealt))],["TIME SURVIVED",format_time(game.elapsed)],["DEPLOYMENT SEED",str(game.match_seed)]]
	for i in rows.size():
		text_at(Vector2(444,348+i*37),rows[i][0],14,muted)
		text_at(Vector2(726,348+i*37),rows[i][1],19)

func format_time(seconds: float) -> String:
	return "%02d:%02d"%[int(seconds)/60,int(seconds)%60]
