extends RefCounted

static var weapons: Dictionary = {}
static var tables: Dictionary = {}
const SUITS = [Color("74836a"), Color("b19270"), Color("78909b")]
const AMMO_PACK = {"light":30, "heavy":18, "shell":8}
const NAMES = {"ammo_light":"LIGHT AMMO", "ammo_heavy":"HEAVY AMMO", "ammo_shell":"SHELLS", "armor25":"FIELD VEST / 25", "armor50":"PLATE VEST / 50", "helmet":"BALLISTIC HELMET", "backpack":"EXTENDED PACK", "bandage":"BANDAGE / +25", "medkit":"MEDKIT / FULL", "grenade":"FRAG GRENADE"}

static func init_data():
	weapons = JSON.parse_string(FileAccess.get_file_as_string("res://data/weapons.json"))
	tables = JSON.parse_string(FileAccess.get_file_as_string("res://data/loot.json"))

static func make_item(id: String) -> Dictionary:
	if weapons.has(id):
		return {"id":id, "rounds":int(weapons[id].mag), "count":1}
	return {"id":id, "count":AMMO_PACK.get(id.trim_prefix("ammo_"), 1)}

static func roll(table: String, rng: RandomNumberGenerator) -> Dictionary:
	var total = 0.0
	for entry in tables[table]: total += entry[1]
	var n = rng.randf() * total
	for entry in tables[table]:
		n -= entry[1]
		if n <= 0: return make_item(entry[0])
	return make_item("bandage")

static func title(item: Dictionary) -> String:
	var id = item.id
	if weapons.has(id): return weapons[id].name
	if id.begins_with("armor"): return "PLATE VEST / "+str(int(ceil(float(id.trim_prefix("armor")))))
	return NAMES.get(id, id)

static func tint(id: String) -> Color:
	if weapons.has(id): return Color(weapons[id].color)
	if id.begins_with("armor") or id == "helmet": return Color("a2b5c3")
	if id in ["bandage", "medkit"]: return Color("b3c68f")
	return Color("cfb881")
