extends Node2D

const MAIN_MENU_STATE = preload("res://source/godotMainMenuState.tscn")

const BPM: float = 102.0
const INTRO_LINES: Array[String] = [
	"ninjamuffin99, PhantomArcade,",
	"kawaisprite, and evilsk8r",
	"present",
	"",
	"In association with",
	"Newgrounds",
	"",
	"A Funkin' Production",
	"",
	"Friday",
	"Night",
	"Funkin'",
	"",
]

@onready var logo: AnimatedSprite2D = $Logo
@onready var girlfriend_dance: AnimatedSprite2D = $GirlfriendDance
@onready var press_enter_text: Label = $PressEnterText
@onready var intro_text: Label = $IntroText
@onready var beat_timer: Timer = $BeatTimer
@onready var intro_timer: Timer = $IntroTimer

var _skipped_intro: bool = false
var _can_press: bool = false
var _beat: int = 0
var _intro_index: int = 0
var _enter_flicker: bool = false
var _flicker_timer: float = 0.0
var _flicker_interval: float = 0.1
var _accepting_input: bool = false

func _ready() -> void:
	beat_timer.wait_time = 60.0 / BPM
	beat_timer.timeout.connect(_on_beat)
	intro_timer.wait_time = 60.0 / BPM
	intro_timer.timeout.connect(_on_intro_step)

	press_enter_text.visible = false

func _process(delta: float) -> void:
	if not _skipped_intro:
		return

	if _accepting_input:
		_flicker_timer += delta
		if _flicker_timer >= _flicker_interval:
			_flicker_timer = 0.0
			_enter_flicker = not _enter_flicker
			press_enter_text.visible = _enter_flicker

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		if not _skipped_intro:
			_skip_intro()
			return

		if _accepting_input:
			_go_to_main_menu()

func _on_beat() -> void:
	_beat += 1
	if logo:
		_bump_logo()
	if girlfriend_dance:
		girlfriend_dance.play("dance")

func _bump_logo() -> void:
	var tween := create_tween()
	logo.scale = Vector2(1.1, 1.1)
	tween.tween_property(logo, "scale", Vector2(1.0, 1.0), 60.0 / BPM * 0.5)

func _on_intro_step() -> void:
	if _skipped_intro:
		return

	if _intro_index < INTRO_LINES.size():
		intro_text.text = INTRO_LINES[_intro_index]
		_intro_index += 1
		intro_timer.start()
	else:
		_finish_intro()

func _finish_intro() -> void:
	_skipped_intro = true
	intro_text.visible = false
	press_enter_text.visible = true
	_accepting_input = true
	_flicker_timer = 0.0

func _skip_intro() -> void:
	intro_timer.stop()
	_finish_intro()

func _go_to_main_menu() -> void:
	_accepting_input = false
	get_tree().change_scene_to_packed(MAIN_MENU_STATE)
