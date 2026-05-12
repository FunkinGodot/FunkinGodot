extends Node

const TITLE_STATE = preload("res://src/states/TitleState.tscn")

@onready var fps_label: Label = $FPSLabel

func _ready() -> void:
	_setup_window()

	if not _is_mobile():
		_setup_fps_counter()

	get_tree().change_scene_to_packed(TITLE_STATE)

func _process(_delta: float) -> void:
	if fps_label and fps_label.visible:
		fps_label.text = "%d FPS" % Engine.get_frames_per_second()

func _setup_window() -> void:
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 60

func _setup_fps_counter() -> void:
	fps_label = Label.new()
	fps_label.name = "FPSLabel"
	fps_label.position = Vector2(10, 3)
	fps_label.add_theme_color_override("font_color", Color.WHITE)
	fps_label.add_theme_font_size_override("font_size", 12)
	fps_label.z_index = 100
	add_child(fps_label)

func _is_mobile() -> bool:
	return OS.has_feature("mobile") or OS.has_feature("android") or OS.has_feature("ios")
