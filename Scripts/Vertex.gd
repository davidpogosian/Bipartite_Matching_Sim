extends Area2D

var index = null
onready var panel = get_parent()

func set_index(i):
	index = i

func get_index():
	return index

func _vertex_pressed(_viewport, event, _shape_idx):
	if event.is_action('left_click') and event.is_pressed():
		panel.set_grabbed(self)
	if event.is_action_released('left_click'):
		var grabbed = panel.get_grabbed()
		if grabbed != null and grabbed != self:
			# don't add redundant lines
			var edges = panel.get_edges()
			for edge in edges:
				if grabbed.get_index() in edge:
					if index in edge:
						return
			# draw line
			var line = Line2D.new()
			line.add_point(grabbed.get_position())
			line.add_point(get_position())
			line.set_begin_cap_mode(Line2D.LINE_CAP_ROUND)
			line.set_end_cap_mode(Line2D.LINE_CAP_ROUND)
			panel.add_child(line)
			panel.add_connection([grabbed.get_index(), index, line])

func _process(delta):
	pass
