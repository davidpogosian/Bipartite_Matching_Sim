extends Camera2D

const MAX_Y: int = 5000
const MIN_Y: int = -5000
const MAX_X: int = 5000
const MIN_X: int = -5000

var _target_zoom: float = 1.0
const MIN_ZOOM: float = 0.1
const MAX_ZOOM: float = 3.0
const ZOOM_RATE: float = 8.0
const ZOOM_INCREMENT: float = 0.1

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		if event.button_mask == BUTTON_MASK_MIDDLE:
			scooch(event.relative * zoom)
	if event is InputEventMouseButton:
		if event.is_pressed():
			if event.button_index == BUTTON_WHEEL_UP:
				zoom_in()
			if event.button_index == BUTTON_WHEEL_DOWN:
				zoom_out()

func scooch(shift: Vector2):
	if shift.x < 0:
		# go right
		shift.x = max(shift.x, position.x - MAX_X)
	else:
		# go left
		shift.x = min(shift.x, position.x - MIN_X)
	if shift.y < 0:
		#go down
		shift.y = max(shift.y, position.y - MAX_Y)
	else:
		#go up
		shift.y = min(shift.y, position.y - MIN_Y)
	position -= shift

func zoom_in() -> void:
	_target_zoom = max(_target_zoom - ZOOM_INCREMENT, MIN_ZOOM)
	set_physics_process(true)

func zoom_out() -> void:
	_target_zoom = min(_target_zoom + ZOOM_INCREMENT, MAX_ZOOM)
	set_physics_process(true)
	
func _physics_process(delta: float) -> void:
	zoom = lerp(
		zoom,
		_target_zoom * Vector2.ONE,
		ZOOM_RATE * delta
	)
	set_physics_process(not is_equal_approx(zoom.x, _target_zoom))
	
