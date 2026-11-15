extends Node2D

# Luminal — optical puzzle engine
# Mirror types: 0 = /   1 = \

const CELL_SIZE: int = 72
const EXIT_COLOR = Color(0.79, 0.88, 0.73, 1.0)

# Directions: 0=right 1=down 2=left 3=up
const DIR_VEC = [Vector2i(1,0), Vector2i(0,1), Vector2i(-1,0), Vector2i(0,-1)]

# Mirror reflections [mirror_type][incoming_dir] -> outgoing_dir
# /  : right→up(3), down→left(2), left→down(1), up→right(0)
# \  : right→down(1), down→right(0), left→up(3), up→left(2)
const REFLECT_SLASH    = {0:3, 1:2, 2:1, 3:0}
const REFLECT_BACKSLASH = {0:1, 1:0, 2:3, 3:2}

var level_data: Dictionary
var grid_size: Vector2i
var grid_offset: Vector2
var walls: Dictionary = {}
var mirrors: Dictionary = {}
var mirrors_placed: int = 0
var mirrors_max: int = 0
var beam_path: Array = []
var hover_cell: Vector2i = Vector2i(-1, -1)
var selected_type: int = 0
var move_count: int = 0
var solved: bool = false
var solving: bool = false

var time_elapsed: float = 0.0
var flash_timer: float = 0.0

func _ready():
	level_data = GameManager.get_level_data(GameManager.current_level)
	if level_data.is_empty():
		push_error("Luminal: missing level data")
		return
	_setup_level()

func _setup_level():
	grid_size = level_data["grid_size"]
	mirrors_max = level_data["mirrors_available"]
	mirrors_placed = 0
	mirrors.clear()
	walls.clear()
	beam_path.clear()
	solved = false
	solving = false
	move_count = 0

	var vp = get_viewport_rect().size
	grid_offset = Vector2(
		(vp.x - grid_size.x * CELL_SIZE) / 2.0,
		(vp.y - grid_size.y * CELL_SIZE) / 2.0 + 20.0
	)

	for w in level_data.get("walls", []):
		walls[w] = true

	_update_ui()
	_trace_beam()
	queue_redraw()

func _update_ui():
	if has_node("UILayer/LevelLabel"):
		$UILayer/LevelLabel.text = "LEVEL %d  —  %s" % [GameManager.current_level + 1, level_data.get("title", "")]
	if has_node("UILayer/SubLabel"):
		$UILayer/SubLabel.text = level_data.get("subtitle", "")
	if has_node("UILayer/MirrorCount"):
		$UILayer/MirrorCount.text = "OPTICS  %d" % (mirrors_max - mirrors_placed)
	if has_node("UILayer/MoveCount"):
		$UILayer/MoveCount.text = "MOVES  %d   /   PAR %d" % [move_count, level_data.get("par", 0)]

func _process(delta):
	time_elapsed += delta
	if flash_timer > 0.0:
		flash_timer -= delta
	queue_redraw()

func _input(event):
	if solving:
		return

	if event is InputEventMouseMotion:
		var c = _screen_to_cell(event.position)
		if c != hover_cell:
			hover_cell = c
			queue_redraw()

	if event is InputEventMouseButton and event.pressed:
		var cell = _screen_to_cell(event.position)
		if not _placeable(cell):
			return

		if event.button_index == MOUSE_BUTTON_LEFT:
			if mirrors.has(cell):
				mirrors[cell] = (mirrors[cell] + 1) % 2
			elif mirrors_placed < mirrors_max:
				mirrors[cell] = selected_type
				mirrors_placed += 1
			else:
				_flash_error()
				return
			move_count += 1
			_trace_beam()
			_update_ui()

		elif event.button_index == MOUSE_BUTTON_RIGHT:
			if mirrors.has(cell):
				mirrors.erase(cell)
				mirrors_placed -= 1
				move_count += 1
				_trace_beam()
				_update_ui()

	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_R:       _reset_level()
			KEY_ESCAPE:  get_tree().change_scene_to_file("res://scenes/Main.tscn")
			KEY_TAB:
				selected_type = (selected_type + 1) % 2
				queue_redraw()

func _screen_to_cell(pos: Vector2) -> Vector2i:
	var local = pos - grid_offset
	return Vector2i(int(local.x / CELL_SIZE), int(local.y / CELL_SIZE))

func _cell_center(cell: Vector2i) -> Vector2:
	return grid_offset + Vector2(cell.x * CELL_SIZE + CELL_SIZE / 2.0, cell.y * CELL_SIZE + CELL_SIZE / 2.0)

func _cell_origin(cell: Vector2i) -> Vector2:
	return grid_offset + Vector2(cell.x * CELL_SIZE, cell.y * CELL_SIZE)

func _in_bounds(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < grid_size.x and cell.y < grid_size.y

func _placeable(cell: Vector2i) -> bool:
	if not _in_bounds(cell): return false
	if walls.has(cell): return false
	if cell == level_data["emitter"]: return false
	if cell == level_data.get("exit", Vector2i(-1,-1)): return false
	if level_data.has("exit2") and cell == level_data["exit2"]: return false
	return true

func _trace_beam():
	beam_path.clear()

	var pos: Vector2i = level_data["emitter"]
	var dir_idx: int = 0
	var emit_dir: Vector2i = level_data["emitter_dir"]
	for i in range(4):
		if DIR_VEC[i] == emit_dir:
			dir_idx = i
			break

	var visited: Dictionary = {}
	var limit: int = grid_size.x * grid_size.y * 4
	beam_path.append(pos)

	for _s in range(limit):
		var nxt: Vector2i = pos + DIR_VEC[dir_idx]

		if not _in_bounds(nxt):
			break
		if walls.has(nxt):
			break

		pos = nxt
		beam_path.append(pos)

		# Loop detection
		var key = Vector3i(pos.x, pos.y, dir_idx)
		if visited.has(key):
			break
		visited[key] = true

		# Exit check
		var hit_exit = (pos == level_data.get("exit", Vector2i(-9,-9)))
		var hit_exit2 = level_data.has("exit2") and pos == level_data["exit2"]
		if hit_exit or hit_exit2:
			if not solving:
				solving = true
				solved = true
				flash_timer = 1.8
				_advance_level()
			break

		# Mirror check
		if mirrors.has(pos):
			var mt: int = mirrors[pos]
			if mt == 0:
				dir_idx = REFLECT_SLASH[dir_idx]
			else:
				dir_idx = REFLECT_BACKSLASH[dir_idx]

func _advance_level():
	await get_tree().create_timer(1.3).timeout
	GameManager.current_level += 1
	if GameManager.current_level >= GameManager.total_levels():
		get_tree().change_scene_to_file("res://scenes/WinScreen.tscn")
	else:
		var tw = create_tween()
		tw.tween_property(self, "modulate:a", 0.0, 0.45)
		tw.tween_callback(func():
			_setup_level()
			var t2 = create_tween()
			t2.tween_property(self, "modulate:a", 1.0, 0.4)
		)

func _flash_error():
	var tw = create_tween()
	tw.tween_property(self, "modulate", Color(0.82, 0.53, 0.25, 1.0), 0.08)
	tw.tween_property(self, "modulate", Color.WHITE, 0.22)

func _reset_level():
	mirrors.clear()
	mirrors_placed = 0
	move_count = 0
	solved = false
	solving = false
	flash_timer = 0.0
	_trace_beam()
	_update_ui()
	queue_redraw()

# ─── DRAWING ────────────────────────────────────────────────────────────────

func _draw():
	_d_background()
	_d_grid()
	_d_walls()
	_d_exits()
	_d_beam()
	_d_mirrors()
	_d_emitter()
	_d_hover()
	_d_selector()

func _d_background():
	var viewport := get_viewport_rect()
	var center := viewport.size * 0.5
	draw_rect(viewport, Color(0.027, 0.039, 0.047, 1.0))
	draw_rect(Rect2(Vector2(0, viewport.size.y * 0.78),
		Vector2(viewport.size.x, viewport.size.y * 0.22)), Color(0.035, 0.052, 0.056, 0.72))
	# Faint optical calibration rings sit behind the puzzle field.
	for i in range(4):
		var radius := 190.0 + float(i) * 88.0
		draw_arc(center, radius, 0.0, TAU, 120,
			Color(0.56, 0.68, 0.59, 0.035 - float(i) * 0.005), 1.0)
	draw_line(Vector2(48, 84), Vector2(viewport.size.x - 48, 84),
		Color(0.72, 0.58, 0.38, 0.10), 1.0)

func _d_grid():
	for x in range(grid_size.x):
		for y in range(grid_size.y):
			var cell = Vector2i(x, y)
			if walls.has(cell):
				continue
			var o = _cell_origin(cell)
			draw_rect(Rect2(o + Vector2(1,1), Vector2(CELL_SIZE - 2, CELL_SIZE - 2)),
				Color(0.070, 0.102, 0.110, 0.92))
			draw_rect(Rect2(o, Vector2(CELL_SIZE, CELL_SIZE)),
				Color(0.40, 0.49, 0.46, 0.18), false, 1.0)

func _d_walls():
	for cell in walls:
		var o = _cell_origin(cell)
		draw_rect(Rect2(o, Vector2(CELL_SIZE, CELL_SIZE)), Color(0.045, 0.067, 0.073, 1.0))
		draw_rect(Rect2(o + Vector2(2,2), Vector2(CELL_SIZE - 4, CELL_SIZE - 4)),
			Color(0.53, 0.40, 0.25, 0.34), false, 1.0)
		# Rune cross
		var cx = _cell_center(cell)
		var s = CELL_SIZE * 0.18
		draw_line(cx + Vector2(-s, 0), cx + Vector2(s, 0), Color(0.70, 0.52, 0.31, 0.38), 1.5)
		draw_line(cx + Vector2(0, -s), cx + Vector2(0, s), Color(0.70, 0.52, 0.31, 0.38), 1.5)

func _d_exits():
	var exits: Array = [level_data.get("exit", Vector2i(-9,-9))]
	if level_data.has("exit2"):
		exits.append(level_data["exit2"])

	var pulse = (sin(time_elapsed * 2.4) + 1.0) * 0.5

	for cell in exits:
		if not _in_bounds(cell):
			continue
		var cx = _cell_center(cell)
		var base_r = CELL_SIZE * 0.28
		var extra = (1.3 + sin(time_elapsed * 7.0) * 0.4) if solved else 1.0

		draw_arc(cx, base_r * extra * 1.35, 0.0, TAU, 40,
			Color(0.42, 0.70, 0.59, 0.10 + 0.06 * pulse), 9.0)
		draw_arc(cx, base_r * extra, 0.0, TAU, 40,
			Color(0.55, 0.79, 0.67, 0.72), 2.5)
		draw_circle(cx, base_r * extra * 0.5, Color(0.30, 0.57, 0.46, 0.62))
		draw_circle(cx, 5.0, EXIT_COLOR)

func _d_beam():
	if beam_path.size() < 2:
		return

	for i in range(beam_path.size() - 1):
		var a = _cell_center(beam_path[i])
		var b = _cell_center(beam_path[i + 1])
		draw_line(a, b, Color(0.39, 0.67, 0.66, 0.10), 18.0)
		draw_line(a, b, Color(0.48, 0.73, 0.69, 0.19), 9.0)
		draw_line(a, b, Color(0.70, 0.86, 0.79, 0.72), 2.8)
		draw_line(a, b, Color(0.95, 0.93, 0.82, 0.94), 1.3)

	# Travelling pulse dot
	var n = float(beam_path.size() - 1)
	if n > 0.0:
		var t = fmod(time_elapsed * 1.6, 1.0)
		var fi = t * n
		var seg = int(fi)
		seg = clamp(seg, 0, beam_path.size() - 2)
		var frac = fi - float(seg)
		var pa = _cell_center(beam_path[seg])
		var pb = _cell_center(beam_path[seg + 1])
		var pp = pa.lerp(pb, frac)
		draw_circle(pp, 7.5, Color(0.86, 0.88, 0.76, 0.64))
		draw_circle(pp, 3.5, Color(1.0, 1.0, 1.0, 0.95))

	# Solve flash overlay
	if flash_timer > 0.0 and solved:
		draw_rect(get_viewport_rect(),
			Color(0.55, 0.75, 0.58, clamp(flash_timer, 0.0, 1.0) * 0.25))

func _d_mirrors():
	for cell in mirrors:
		var mt: int = mirrors[cell]
		var cx = _cell_center(cell)
		var h = CELL_SIZE * 0.34

		# Pick endpoints
		var a: Vector2
		var b: Vector2
		if mt == 0:  # /
			a = cx + Vector2(-h,  h)
			b = cx + Vector2( h, -h)
		else:         # \
			a = cx + Vector2(-h, -h)
			b = cx + Vector2( h,  h)

		draw_circle(cx, h * 1.1, Color(0.74, 0.53, 0.31, 0.12))
		draw_line(a, b, Color(0.78, 0.62, 0.39, 0.24), 9.0)
		draw_line(a, b, Color(0.91, 0.76, 0.52, 1.0),  2.2)
		draw_line(a, b, Color(1.0,  0.91, 0.73, 0.72), 0.9)
		draw_circle(a, 2.8, Color(0.91, 0.76, 0.52, 1.0))
		draw_circle(b, 2.8, Color(0.91, 0.76, 0.52, 1.0))

func _d_emitter():
	var cell: Vector2i = level_data["emitter"]
	var cx = _cell_center(cell)
	var pulse = (sin(time_elapsed * 3.2) + 1.0) * 0.5
	var r = CELL_SIZE * 0.3 + pulse * 3.5

	draw_arc(cx, r + 10.0, 0.0, TAU, 32, Color(0.82, 0.53, 0.25, 0.10 * pulse), 8.0)
	draw_arc(cx, r + 4.0,  0.0, TAU, 32, Color(0.91, 0.65, 0.34, 0.22 * pulse), 3.5)
	draw_circle(cx, r, Color(0.84, 0.58, 0.30, 0.96))
	draw_circle(cx, r * 0.48, Color(0.98, 0.82, 0.55, 1.0))

	# Direction tick
	var dv = level_data["emitter_dir"]
	var tip = cx + Vector2(dv.x, dv.y) * (r + 12.0)
	draw_line(cx + Vector2(dv.x, dv.y) * r, tip,
		Color(0.98, 0.86, 0.63, 0.90), 2.0)

func _d_hover():
	if not _in_bounds(hover_cell): return
	if not _placeable(hover_cell): return
	if solving: return

	var o  = _cell_origin(hover_cell)
	var cx = _cell_center(hover_cell)
	var h  = CELL_SIZE * 0.34

	var preview_type = selected_type
	if mirrors.has(hover_cell):
		preview_type = (mirrors[hover_cell] + 1) % 2

	var a: Vector2
	var b: Vector2
	if preview_type == 0:
		a = cx + Vector2(-h,  h)
		b = cx + Vector2( h, -h)
	else:
		a = cx + Vector2(-h, -h)
		b = cx + Vector2( h,  h)

	draw_rect(Rect2(o + Vector2(1,1), Vector2(CELL_SIZE-2, CELL_SIZE-2)),
		Color(0.68, 0.52, 0.33, 0.12))
	draw_rect(Rect2(o, Vector2(CELL_SIZE, CELL_SIZE)),
		Color(0.78, 0.63, 0.41, 0.52), false, 1.5)
	draw_line(a, b, Color(0.91, 0.76, 0.52, 0.42), 2.5)

func _d_selector():
	var base = Vector2(28.0, get_viewport_rect().size.y - 78.0)
	draw_rect(Rect2(base, Vector2(118, 50)), Color(0.055, 0.082, 0.087, 0.94))
	draw_rect(Rect2(base, Vector2(118, 50)), Color(0.67, 0.54, 0.36, 0.38), false, 1.5)

	for i in range(2):
		var c = Vector2(base.x + 22.0 + i * 56.0, base.y + 25.0)
		var h = 14.0

		if i == selected_type:
			draw_arc(c, 19.0, 0.0, TAU, 24, Color(0.86, 0.69, 0.43, 0.52), 2.0)

		var col = Color(0.91, 0.76, 0.52, 0.92 if i == selected_type else 0.42)
		if i == 0:
			draw_line(c + Vector2(-h,  h), c + Vector2( h, -h), col, 2.0)
		else:
			draw_line(c + Vector2(-h, -h), c + Vector2( h,  h), col, 2.0)
