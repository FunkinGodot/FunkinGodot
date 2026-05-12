extends Node2D

const TITLE_STATE      = preload("res://source/godot/TitleState.tscn")
const STORY_MENU_STATE = preload("res://source/godot/StoryMenuState.tscn")
const FREEPLAY_STATE   = preload("res://source/godot/FreeplayState.tscn")

const MENU_BG_PATH      := "res://assets/images/menuBG.png"
const MENU_DESAT_PATH   := "res://assets/images/menuDesat.png"
const ATLAS_PNG_PATH    := "res://assets/images/FNF_main_menu_assets.png"
const ATLAS_XML_PATH    := "res://assets/images/FNF_main_menu_assets.xml"
const SCROLL_SFX_PATH   := "res://assets/sounds/scrollMenu.ogg"
const CONFIRM_SFX_PATH  := "res://assets/sounds/confirmMenu.ogg"
const FREAKY_MUSIC_PATH := "res://assets/music/freakyMenu.ogg"
const DONATE_URL        := "https://ninja-muffin24.itch.io/funkin"
const FONT_NAME         := "VCR OSD Mono"
const BG_SCALE          := 1.1
const ITEM_SPACING      := 160
const ITEM_START_Y      := 60
const MUSIC_FADE_SPEED  := 0.5
const MUSIC_TARGET_VOL  := 0.8
const CAM_LERP          := 0.06
const FLICKER_CONFIRM_DURATION := 1.1
const FLICKER_CONFIRM_INTERVAL := 0.15
const FLICKER_ITEM_DURATION    := 1.0
const FLICKER_ITEM_INTERVAL    := 0.06
const FADE_OUT_DURATION        := 0.4

const OPTIONS: Array[String] = ["story mode", "freeplay", "donate"]

@onready var camera: Camera2D        = $Camera
@onready var background: Sprite2D    = $Background
@onready var magenta: Sprite2D       = $Magenta
@onready var menu_items_node: Node2D = $MenuItems
@onready var version_text: Label     = $VersionText

var _cur_selected: int = 0
var _selected_something: bool = false
var _menu_items: Array[AnimatedSprite2D] = []
var _cam_target: Vector2 = Vector2.ZERO
var _music_player: AudioStreamPlayer
var _sfx_scroll: AudioStream
var _sfx_confirm: AudioStream
var _atlas_frames: SpriteFrames

func _ready() -> void:
	_setup_music()
	_setup_background()
	_setup_magenta()
	_setup_atlas()
	_setup_menu_items()
	_setup_version_text()
	_change_item(0)

func _process(delta: float) -> void:
	_fade_music_in(delta)
	_smooth_camera()

func _input(event: InputEvent) -> void:
	if _selected_something:
		return

	if event.is_action_pressed("ui_up"):
		_play_sfx(_sfx_scroll)
		_change_item(-1)

	elif event.is_action_pressed("ui_down"):
		_play_sfx(_sfx_scroll)
		_change_item(1)

	elif event.is_action_pressed("ui_cancel"):
		get_tree().change_scene_to_packed(TITLE_STATE)

	elif event.is_action_pressed("ui_accept"):
		_on_accept()

func _setup_music() -> void:
	_music_player = AudioStreamPlayer.new()
	add_child(_music_player)
	_music_player.stream = load(FREAKY_MUSIC_PATH)
	if not _music_player.playing:
		_music_player.volume_db = linear_to_db(0.0)
		_music_player.play()

func _fade_music_in(delta: float) -> void:
	var current_vol := db_to_linear(_music_player.volume_db)
	if current_vol < MUSIC_TARGET_VOL:
		_music_player.volume_db = linear_to_db(
			minf(current_vol + MUSIC_FADE_SPEED * delta, MUSIC_TARGET_VOL)
		)

func _setup_background() -> void:
	var tex: Texture2D = load(MENU_BG_PATH)
	background.texture = tex
	background.position.x = -80
	background.scale = Vector2(BG_SCALE, BG_SCALE)
	background.centered = true

func _setup_magenta() -> void:
	var tex: Texture2D = load(MENU_DESAT_PATH)
	magenta.texture = tex
	magenta.position.x = -80
	magenta.scale = Vector2(BG_SCALE, BG_SCALE)
	magenta.centered = true
	magenta.visible = false

func _setup_atlas() -> void:
	_atlas_frames = _load_sparrow_atlas(ATLAS_PNG_PATH, ATLAS_XML_PATH)

func _setup_menu_items() -> void:
	var viewport_size := get_viewport_rect().size

	for i in OPTIONS.size():
		var item := AnimatedSprite2D.new()
		item.sprite_frames = _atlas_frames
		item.animation_finished.connect(func(): pass)

		var idle_anim    := OPTIONS[i] + " basic"
		var selected_anim := OPTIONS[i] + " white"

		if _atlas_frames.has_animation(idle_anim):
			item.play(idle_anim)

		item.position = Vector2(viewport_size.x / 2.0, ITEM_START_Y + i * ITEM_SPACING)
		item.set_meta("id", i)
		item.set_meta("idle_anim", idle_anim)
		item.set_meta("selected_anim", selected_anim)

		menu_items_node.add_child(item)
		_menu_items.append(item)

func _setup_version_text() -> void:
	version_text.text = "v" + ProjectSettings.get_setting("application/config/version", "0.0.0")
	version_text.position = Vector2(5, get_viewport_rect().size.y - 22)
	version_text.add_theme_font_size_override("font_size", 16)
	version_text.add_theme_color_override("font_color", Color.WHITE)
	version_text.add_theme_color_override("font_outline_color", Color.BLACK)
	version_text.add_theme_constant_override("outline_size", 2)

func _change_item(direction: int = 0) -> void:
	_cur_selected = wrapi(_cur_selected + direction, 0, _menu_items.size())

	for item in _menu_items:
		var item_id: int = item.get_meta("id")
		var idle_anim: String = item.get_meta("idle_anim")
		var selected_anim: String = item.get_meta("selected_anim")

		if item_id == _cur_selected:
			if _atlas_frames.has_animation(selected_anim):
				item.play(selected_anim)
			_cam_target = item.position
		else:
			if _atlas_frames.has_animation(idle_anim):
				item.play(idle_anim)

func _smooth_camera() -> void:
	camera.position = camera.position.lerp(_cam_target, CAM_LERP)

func _on_accept() -> void:
	var choice := OPTIONS[_cur_selected]

	if choice == "donate":
		OS.shell_open(DONATE_URL)
		return

	_selected_something = true
	_play_sfx(_sfx_confirm)

	_flicker_sprite(magenta, FLICKER_CONFIRM_DURATION, FLICKER_CONFIRM_INTERVAL, false)

	for item in _menu_items:
		var item_id: int = item.get_meta("id")
		if item_id != _cur_selected:
			var tween := create_tween()
			tween.tween_property(item, "modulate:a", 0.0, FADE_OUT_DURATION)\
				.set_ease(Tween.EASE_OUT)\
				.set_trans(Tween.TRANS_QUAD)
			tween.tween_callback(item.queue_free)
		else:
			_flicker_sprite(item, FLICKER_ITEM_DURATION, FLICKER_ITEM_INTERVAL, true,
				func(_spr: AnimatedSprite2D) -> void:
					_go_to_choice(choice)
			)

func _go_to_choice(choice: String) -> void:
	match choice:
		"story mode":
			get_tree().change_scene_to_packed(STORY_MENU_STATE)
		"freeplay":
			get_tree().change_scene_to_packed(FREEPLAY_STATE)

func _flicker_sprite(
	target: Node,
	duration: float,
	interval: float,
	end_visible: bool,
	on_complete: Callable = Callable()
) -> void:
	var elapsed := 0.0
	var visible_state := true
	var tween := create_tween().set_loops()

	tween.tween_interval(interval)
	tween.tween_callback(func() -> void:
		elapsed += interval
		visible_state = not visible_state
		target.visible = visible_state
		if elapsed >= duration:
			tween.kill()
			target.visible = end_visible
			if on_complete.is_valid():
				on_complete.call(target)
	)

func _play_sfx(stream: AudioStream) -> void:
	if stream == null:
		return
	var player := AudioStreamPlayer.new()
	add_child(player)
	player.stream = stream
	player.play()
	player.finished.connect(player.queue_free)

func _load_sparrow_atlas(png_path: String, xml_path: String) -> SpriteFrames:
	var frames := SpriteFrames.new()
	var texture: Texture2D = load(png_path)

	var xml_file := FileAccess.open(xml_path, FileAccess.READ)
	if xml_file == null:
		push_error("MainMenuState: could not open atlas XML at %s" % xml_path)
		return frames

	var parser := XMLParser.new()
	parser.open(xml_path)

	var regions: Dictionary = {}

	while parser.read() == OK:
		if parser.get_node_type() != XMLParser.NODE_ELEMENT:
			continue
		if parser.get_node_name() != "SubTexture":
			continue

		var name_raw: String = parser.get_named_attribute_value("name")
		var x: int      = int(parser.get_named_attribute_value("x"))
		var y: int      = int(parser.get_named_attribute_value("y"))
		var w: int      = int(parser.get_named_attribute_value("width"))
		var h: int      = int(parser.get_named_attribute_value("height"))

		var base_name := name_raw.rstrip("0123456789")
		if not regions.has(base_name):
			regions[base_name] = []
		regions[base_name].append({"x": x, "y": y, "w": w, "h": h})

	for anim_name in regions.keys():
		frames.add_animation(anim_name)
		frames.set_animation_speed(anim_name, 24)
		frames.set_animation_loop(anim_name, true)
		for region in regions[anim_name]:
			var atlas := AtlasTexture.new()
			atlas.atlas = texture
			atlas.region = Rect2(region.x, region.y, region.w, region.h)
			frames.add_frame(anim_name, atlas)

	return frames
