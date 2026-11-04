extends SceneTree
func _initialize():
	var f = FileAccess.open("res://docs/GODOT-LICENSE.txt",FileAccess.WRITE)
	f.store_string(Engine.get_license_text())
	var notices = FileAccess.open("res://docs/THIRD_PARTY_NOTICES.json",FileAccess.WRITE)
	notices.store_string(JSON.stringify({"copyright":Engine.get_copyright_info(),"licenses":Engine.get_license_info()},"  "))
	quit()
