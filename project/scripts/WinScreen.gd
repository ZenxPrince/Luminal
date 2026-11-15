extends Control

var time_elapsed: float = 0.0
var ripple_timer: float = 0.0
var ripples: Array = []
var CENTER := Vector2(640, 360)

func _ready() -> void:
	$VBoxContainer/RestartButton.pressed.connect(_on_restart_pressed)
	$VBoxContainer/TitleLabel.modulate.a = 0.0
	$VBoxContainer/SubLabel.modulate.a = 0.0
	$VBoxContainer/RestartButton.modulate.a = 0.0
	$VBoxContainer/TitleLabel.add_theme_color_override("font_color", Color("#E8E4D7"))
	$VBoxContainer/SubLabel.add_theme_color_override("font_color", Color("#9BA99D"))

	var style := StyleBoxFlat.new()
	style.bg_color = Color("#D4A66A")
	style.border_color = Color("#E7C28B")
	style.set_border_width_all(1)
	style.set_corner_radius_all(5)
	$VBoxContainer/RestartButton.add_theme_stylebox_override("normal", style)
	$VBoxContainer/RestartButton.add_theme_color_override("font_color", Color("#18201D"))

	var tw := create_tween().set_parallel(true)
	tw.tween_property($VBoxContainer/TitleLabel, "modulate:a", 1.0, 1.2).set_delay(0.35)
	tw.tween_property($VBoxContainer/SubLabel, "modulate:a", 1.0, 0.9).set_delay(1.0)
	tw.tween_property($VBoxContainer/RestartButton, "modulate:a", 1.0, 0.75).set_delay(1.55)

func _process(delta: float) -> void:
	time_elapsed += delta
	ripple_timer += delta
	if ripple_timer >= 0.8:
		ripple_timer = 0.0
		ripples.append({"age": 0.0, "max": 2.4})
	for r in ripples:
		r["age"] += delta
	ripples = ripples.filter(func(r): return r["age"] < r["max"])
	queue_redraw()

func _draw() -> void:
	var size := get_viewport_rect().size
	draw_rect(Rect2(Vector2.ZERO, size), Color("#070D10"))
	draw_rect(Rect2(Vector2(0, size.y * 0.72), Vector2(size.x, size.y * 0.28)), Color("#0A1214"))
	for i in range(6):
		draw_arc(CENTER, 70.0 + float(i) * 54.0, 0.0, TAU, 100,
			Color(0.56, 0.70, 0.61, 0.10 - float(i) * 0.012), 1.0)
	for r in ripples:
		var t: float = r["age"] / r["max"]
		draw_arc(CENTER, t * 360.0, 0.0, TAU, 72,
			Color(0.63, 0.77, 0.66, (1.0 - t) * 0.20), 1.2)
	var pulse := (sin(time_elapsed * 1.25) + 1.0) * 0.5
	draw_circle(CENTER, 13.0 + pulse * 3.0, Color(0.83, 0.64, 0.39, 0.85))
	draw_circle(CENTER, 35.0 + pulse * 8.0, Color(0.83, 0.64, 0.39, 0.035))

func _on_restart_pressed() -> void:
	GameManager.current_level = 0
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.38)
	tw.tween_callback(func(): get_tree().change_scene_to_file("res://scenes/Main.tscn"))
