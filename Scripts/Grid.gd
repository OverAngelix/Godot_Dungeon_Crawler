extends Node2D

const GRID_SIZE := 10
const CELL_SIZE := 60
const GRID_OFFSET := Vector2(50.0, 80.0)

const COLOR_EMPTY   := Color(0.15, 0.13, 0.20)
const COLOR_FILLED  := Color(0.42, 0.32, 0.22)
const COLOR_LINE    := Color(0.45, 0.45, 0.55, 0.45)
const COLOR_OK      := Color(0.35, 0.80, 0.40, 0.55)
const COLOR_BAD     := Color(0.85, 0.25, 0.25, 0.55)
const COLOR_TEXT    := Color(0.92, 0.87, 0.70)

var grid: Array = [] #GRID OF TRUE IF WAY OR FALSE
var current_shape: int = 1 #SHAPE TO DRAW DUNGEON (LINE OR ZIGZAG)
var hover_cell := Vector2i(-1, -1) #CELL NO IN GRID

var shapes := {
	1: [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0)], # LINE
	2: [Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1), Vector2i(2, 1)] # ZIGZAG
}


func _ready() -> void: # CREATE A EMPTY GRID OF GRID_SIZE x GRID_SIZE
	grid.resize(GRID_SIZE)
	for row in range(GRID_SIZE):
		grid[row] = []
		grid[row].resize(GRID_SIZE)
		grid[row].fill(false)

var shape_map := { "line": 1, "zigzag": 2 }

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo: #CHANGE SHAPE WITH INPUT CONTROLLER
		for action in shape_map:
			if event.is_action(action):
				current_shape = shape_map[action]
				queue_redraw()
				break

	if event is InputEventMouseMotion:
		var new_hover := _get_cell_at(event.position)
		if new_hover != hover_cell:
			hover_cell = new_hover
			queue_redraw()

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_place_shape(hover_cell)


func _get_cell_at(screen_pos: Vector2) -> Vector2i:
	var local := screen_pos - GRID_OFFSET
	var col := int(local.x / CELL_SIZE)
	var row := int(local.y / CELL_SIZE)
	if col < 0 or col >= GRID_SIZE or row < 0 or row >= GRID_SIZE:
		return Vector2i(-1, -1)
	return Vector2i(col, row)


func _get_shape_cells(anchor: Vector2i) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for offset: Vector2i in shapes[current_shape]:
		cells.append(anchor + offset)
	return cells


func _is_valid(cells: Array[Vector2i]) -> bool:
	for cell in cells:
		if cell.x < 0 or cell.x >= GRID_SIZE or cell.y < 0 or cell.y >= GRID_SIZE:
			return false
		if grid[cell.y][cell.x]:
			return false
	return true


func _place_shape(anchor: Vector2i) -> void:
	if anchor == Vector2i(-1, -1):
		return
	var cells := _get_shape_cells(anchor)
	if _is_valid(cells):
		for cell in cells:
			grid[cell.y][cell.x] = true
		queue_redraw()


func _draw() -> void:
	for row in range(GRID_SIZE):
		for col in range(GRID_SIZE):
			var pos := GRID_OFFSET + Vector2(col * CELL_SIZE, row * CELL_SIZE)
			var rect := Rect2(pos + Vector2(1, 1), Vector2(CELL_SIZE - 2, CELL_SIZE - 2))
			var color := COLOR_FILLED if grid[row][col] else COLOR_EMPTY
			draw_rect(rect, color)

	if hover_cell != Vector2i(-1, -1):
		var preview_cells := _get_shape_cells(hover_cell)
		var valid := _is_valid(preview_cells)
		var preview_color := COLOR_OK if valid else COLOR_BAD
		for cell in preview_cells:
			if cell.x >= 0 and cell.x < GRID_SIZE and cell.y >= 0 and cell.y < GRID_SIZE:
				var pos := GRID_OFFSET + Vector2(cell.x * CELL_SIZE, cell.y * CELL_SIZE)
				draw_rect(Rect2(pos + Vector2(1, 1), Vector2(CELL_SIZE - 2, CELL_SIZE - 2)), preview_color)

	var grid_end := GRID_OFFSET + Vector2(GRID_SIZE * CELL_SIZE, GRID_SIZE * CELL_SIZE)
	for i in range(GRID_SIZE + 1):
		var x := GRID_OFFSET.x + i * CELL_SIZE
		var y := GRID_OFFSET.y + i * CELL_SIZE
		draw_line(Vector2(x, GRID_OFFSET.y), Vector2(x, grid_end.y), COLOR_LINE)
		draw_line(Vector2(GRID_OFFSET.x, y), Vector2(grid_end.x, y), COLOR_LINE)

	var font := ThemeDB.fallback_font
	var font_size := 15
	var shape_label := "3 cellules alignées  [ X ][ X ][ X ]" if current_shape == 1 \
		else "Zigzag  [ X ][ X ]/[ X ][ X ]"
	draw_string(font,
		Vector2(GRID_OFFSET.x, 35),
		"Forme [%d] : %s        (1 = ligne  |  2 = zigzag)" % [current_shape, shape_label],
		HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, COLOR_TEXT)

	var legend_y := GRID_OFFSET.y + GRID_SIZE * CELL_SIZE + 25
	draw_string(font,
		Vector2(GRID_OFFSET.x, legend_y),
		"Clic gauche : placer    Vert = OK    Rouge = impossible",
		HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, COLOR_TEXT)
