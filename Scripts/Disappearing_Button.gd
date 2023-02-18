extends Area2D

var algo = null

func set_algo(string):
	algo = string

func _on_Disappearing_Button_input_event(_viewport, event, _shape_idx):
	if event.is_action('left_click') and event.is_pressed():
		get_parent().new_panel(algo, position)
		queue_free()
