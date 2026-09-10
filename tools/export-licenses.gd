extends SceneTree

func _initialize():
	var output = FileAccess.open("res://build/web/THIRD-PARTY-LICENSES.txt", FileAccess.WRITE)
	output.store_string("GODOT ENGINE\n\n" + Engine.get_license_text() + "\n\n")
	output.store_string(JSON.stringify(Engine.get_copyright_info(), "  ") + "\n\n")
	var licenses = Engine.get_license_info()
	for name in licenses:
		output.store_string(name + "\n" + str(licenses[name]) + "\n\n")
	output.store_string("NOTO SANS KR\n\n" + FileAccess.get_file_as_string("res://assets/FONT-LICENSE.txt"))
	output.close()
	quit()
