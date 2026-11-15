extends Control

var time_elapsed: float = 0.0

const INK := Color("#070D10")
const DEEP := Color("#0D171A")
const JADE := Color("#8FB8A1")
const BRASS := Color("#D4A66A")
const PAPER := Color("#E8E4D7")
const MUTED := Color("#8D9A91")

func _ready() -> void:
	$VBoxContainer/StartButton.pressed.connect(_on_start_pressed)
	$VBoxContainer/TitleLabel.modulate.a = 0.0
	$VBoxContainer/SubLabel.modulate.a = 0.0
	$VBoxContainer/StartButton.modulate.a = 0.0
	$VBoxContainer/HintLabel.modulate.a = 0.0

	var button_style := StyleBoxFlat.new()
	button_style.bg_color = Color("#D4A66A")
	button_style.border_color = Color("#E7C28B")
	button_style.set_border_width_all(1)
	button_style.set_corner_radius_all(5)
	button_style.content_margin_left = 28
	button_style.content_margin_right = 28
	button_style.content_margin_top = 12
	button_style.content_margin_bottom = 12
	$VBoxContainer/StartButton.add_theme_stylebox_override("normal", button_style)

	var hover_style := button_style.duplicate()
	hover_style.bg_color = Color("#E4BD83")
	$VBoxContainer/StartButton.add_theme_stylebox_override("hover", hover_style)
	var pressed_style := button_style.duplicate()
	pressed_style.bg_color = Color("#B98A50")
	$VBoxContainer/StartButton.add_theme_stylebox_override("pressed", pressed_style)
	$VBoxContainer/StartButton.add_theme_color_override("font_color", Color("#18201D"))
	$VBoxContainer/StartButton.add_theme_color_override("font_hover_color", Color("#101815"))
	$VBoxContainer/StartButton.add_theme_font_size_override("font_size", 15)

	$VBoxContainer/TitleLabel.add_theme_color_override("font_color", PAPER)
	$VBoxContainer/SubLabel.add_theme_color_override("font_color", MUTED)
	$VBoxContainer/HintLabel.add_theme_color_override("font_color", Color("#77857D"))

	var tw := create_tween().set_parallel(true)
	tw.tween_property($VBoxContainer/TitleLabel, "modulate:a", 1.0, 1.2).set_delay(0.25)
	tw.tween_property($VBoxContainer/SubLabel, "modulate:a", 1.0, 0.9).set_delay(0.85)
	tw.tween_property($VBoxContainer/StartButton, "modulate:a", 1.0, 0.75).set_delay(1.25)
	tw.tween_property($VBoxContainer/HintLabel, "modulate:a", 1.0, 0.7).set_delay(1.65)

func _process(delta: float) -> void:
	time_elapsed += delta
	queue_redraw()

func _draw() -> void:
	var size := get_viewport_rect().size
	draw_rect(Rect2(Vector2.ZERO, size), INK)
	# Layered, low-contrast optical field: architectural rings, not decorative neon.
	draw_rect(Rect2(Vector2(0, size.y * 0.72), Vector2(size.x, size.y * 0.28)), Color("#0A1214"))
	for i in range(5):
		var radius := 115.0 + float(i) * 54.0
		var alpha := 0.10 - float(i) * 0.014
		draw_arc(Vector2(size.x * 0.5, size.y * 0.48), radius, 0.0, TAU, 100,
			Color(0.56, 0.70, 0.61, alpha), 1.0)
	draw_line(Vector2(72, size.y - 72), Vector2(size.x - 72, size.y - 72), Color(0.73, 0.60, 0.40, 0.18), 1.0)
	draw_line(Vector2(72, 72), Vector2(size.x - 72, 72), Color(0.73, 0.60, 0.40, 0.10), 1.0)
	# A single restrained source of light.
	var pulse := 0.5 + 0.5 * sin(time_elapsed * 1.15)
	draw_circle(Vector2(size.x * 0.5, size.y * 0.48), 3.0 + pulse * 1.5, Color(0.91, 0.73, 0.48, 0.78))
	draw_circle(Vector2(size.x * 0.5, size.y * 0.48), 28.0 + pulse * 5.0, Color(0.74, 0.57, 0.34, 0.035))

func _on_start_pressed() -> void:
	GameManager.current_level = 0
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.38)
	tw.tween_callback(func(): get_tree().change_scene_to_file("res://scenes/Game.tscn"))
