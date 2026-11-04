extends RefCounted
const Catalog = preload("res://scripts/catalog.gd")
var guns: Array = [{}, {}]
var active = 2
var ammo = {"light":0, "heavy":0, "shell":0}
var supplies = {"bandage":0, "medkit":0, "grenade":0}
var armor = 0.0
var helmet = false
var backpack = false

func capacity() -> int: return 240 if backpack else 120
func used() -> int:
	return int(ammo.light + ammo.heavy + ammo.shell * 2 + (supplies.bandage + supplies.medkit + supplies.grenade) * 8)
func gun() -> Dictionary: return guns[active] if active < 2 else {}
func stats() -> Dictionary: return Catalog.weapons.get(gun().get("id", ""), {})

# Returns leftovers / replaced equipment. Ownership moves only after acceptance.
func pickup(item: Dictionary) -> Dictionary:
	var id: String = item.id
	if Catalog.weapons.has(id):
		var slot = 0 if guns[0].is_empty() else (1 if guns[1].is_empty() else mini(active, 1))
		var old: Dictionary = guns[slot]
		guns[slot] = item.duplicate(true)
		active = slot
		return old
	if id.begins_with("ammo_"):
		var kind = id.trim_prefix("ammo_")
		var weight = 2 if kind == "shell" else 1
		var take = mini(int(item.count), int((capacity() - used()) / weight))
		ammo[kind] += take
		if take < item.count: return {"id":id, "count":item.count - take}
	elif supplies.has(id):
		if used() + 8 > capacity(): return item
		supplies[id] += 1
	elif id.begins_with("armor"):
		var value = float(id.trim_prefix("armor"))
		if armor >= value: return item
		var old = armor
		armor = value
		if old > 0: return {"id":"armor" + str(old), "count":1}
	elif id == "helmet":
		if helmet: return item
		helmet = true
	elif id == "backpack":
		if backpack: return item
		backpack = true
	return {}

func drop_gun(slot: int) -> Dictionary:
	var result: Dictionary = guns[slot]
	guns[slot] = {}
	if active == slot: active = 2
	return result

func drop_supply(id: String) -> Dictionary:
	if supplies.get(id, 0) <= 0: return {}
	supplies[id] -= 1
	return {"id":id, "count":1}

func drop_equipment(id: String) -> Dictionary:
	if id=="armor" and armor>0:
		var old = armor
		armor = 0
		return {"id":"armor"+str(old),"count":1}
	if id=="helmet" and helmet:
		helmet = false
		return {"id":id,"count":1}
	if id=="backpack" and backpack and used()<=120:
		backpack = false
		return {"id":id,"count":1}
	return {}

func reload_mag():
	var g = gun()
	if g.is_empty(): return
	var s = stats()
	var take = mini(int(s.mag) - int(g.rounds), ammo[s.ammo])
	g.rounds += take
	ammo[s.ammo] -= take
