extends RefCounted
var values = {"master":0.8, "music":0.25, "sfx":0.85, "sensitivity":1.0, "shake":0.45, "fullscreen":false, "suit":0, "difficulty":0, "ui_scale":1.0}
var path = "user://settings.cfg"

func load_settings():
	var config = ConfigFile.new()
	if config.load(path) == OK:
		for key in values: values[key] = config.get_value("player", key, values[key])
	apply()

func save():
	var config = ConfigFile.new()
	for key in values: config.set_value("player", key, values[key])
	config.save(path)
	apply()

func apply():
	for bus in ["Master", "Music", "SFX"]:
		var index = AudioServer.get_bus_index(bus)
		if index >= 0: AudioServer.set_bus_volume_db(index, linear_to_db(maxf(0.0001, values[bus.to_lower()])))
	if DisplayServer.get_name() != "headless":
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if values.fullscreen else DisplayServer.WINDOW_MODE_WINDOWED)
