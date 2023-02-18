extends Node

# YOU CAN ADD NON-BIPARTITE GRAPHS, NOT GOOD
# make this modular, so I can have a few of these open in one window,
# make a panel at the bottom that shows runtime and name of algorithm

# put this junk on gh

var vertex = preload('res://Prefabs/Vertex.tscn')
var input = preload('res://Prefabs/Input.tscn')
var line_texture = preload('res://Textures/line_color.png')
var match_texture = preload('res://Textures/line_color_match.png')
var merri_theme = preload('res://Fonts/Merriweather_theme.tres')

var my_algorithm = null

# inputs
var l_input = null
var r_input = null

var l_vertices = 0
var r_vertices = 0
var connections = []
var l_sprites = []
var r_sprites = []
var edges = []

var TOP = 50
var VERTEX_SPACE = 100
var LEFT_COLUMN = 0
var RIGHT_COLUMN = 400

var MAX_VERTICES = 10

var grabbed = null

func _ready():
	# create label
	var label = RichTextLabel.new()
	label.set_text(my_algorithm)
	label.set('theme', merri_theme)
	label.set_position(Vector2((RIGHT_COLUMN + LEFT_COLUMN) / 2, TOP))
	label.rect_min_size = (Vector2(150, 30))
	add_child(label)

	# create inputs
	l_input = input.instance()
	l_input.placeholder_text = '# left vertices'
	l_input.set_position(Vector2(LEFT_COLUMN, TOP))
	l_input.connect('text_changed', self, '_input_changed', [0])
	add_child(l_input)
	
	r_input = input.instance()
	r_input.placeholder_text = '# right vertices'
	r_input.set_position(Vector2(RIGHT_COLUMN, TOP))
	r_input.connect('text_changed', self, '_input_changed', [1])
	add_child(r_input)

# out of order
func copy_panel(panel):
	l_vertices = panel.get_u()
	r_vertices = panel.get_v()
	
	for edge in panel.get_edges():
		edges.append(edge)
	
	for edge in edges:
		var line = Line2D.new()
		
		var index = edge[0]
		var start = Vector2.ZERO
		if index < MAX_VERTICES:
			start.x = LEFT_COLUMN
			start.y = TOP + VERTEX_SPACE + VERTEX_SPACE * index
		else:
			start.x = RIGHT_COLUMN
			start.y = TOP + VERTEX_SPACE + VERTEX_SPACE * (index - 10)
			
		index = edge[1]
		var end = Vector2.ZERO
		if index < MAX_VERTICES:
			end.x = LEFT_COLUMN
			end.y = TOP + VERTEX_SPACE + VERTEX_SPACE * index
		else:
			end.x = RIGHT_COLUMN
			end.y = TOP + VERTEX_SPACE + VERTEX_SPACE * (index - 10)
			
		line.add_point(start)
		line.add_point(end)
		line.set_begin_cap_mode(Line2D.LINE_CAP_ROUND)
		line.set_end_cap_mode(Line2D.LINE_CAP_ROUND)
		add_child(line)
		connections.append([edge[0], edge[1], line])
	update()
	
func get_u():
	return l_vertices
	
func get_v():
	return r_vertices

func set_algorithm(string):
	my_algorithm = string

func get_algorithm():
	return my_algorithm

func set_grabbed(obj):
	grabbed = obj

func get_grabbed():
	return grabbed

func add_connection(tuple):
	connections.append(tuple)
	edges.append([tuple[0], tuple[1]])

func get_connections():
	return connections

func delete_vertex(option):
	var del_vertex = null
	if option == 'l':
		del_vertex = l_sprites.pop_back()
	if option == 'r':
		del_vertex = r_sprites.pop_back()
	var del_index = del_vertex.get_index()
	del_vertex.queue_free()
	# get rid of connections of deleted vertex
	var new_connections = []
	var new_edges = []
	for tuple in connections:
		if del_index in tuple:
			# delete line
			tuple[2].queue_free()
		else:
			new_connections.append(tuple)
			new_edges.append([tuple[0], tuple[1]])
	connections = new_connections
	edges = new_edges

func add_vertex(index, pos):
	var new_vertex = vertex.instance()
	new_vertex.set_index(index)
	new_vertex.set_position(pos)
	if index < MAX_VERTICES:
		l_sprites.append(new_vertex)
	else:
		r_sprites.append(new_vertex)
	add_child(new_vertex)

func update():
	# check if need to increase or decrease number of vertices
	var r_difference = r_vertices - len(r_sprites)
	var l_difference = l_vertices - len(l_sprites)
	
	# handle right vertices
	if r_difference > 0:
		for i in range(len(r_sprites), r_vertices):
			add_vertex(i + MAX_VERTICES, Vector2(RIGHT_COLUMN, TOP + VERTEX_SPACE + VERTEX_SPACE * i))
	if r_difference < 0:
		for _i in range(len(r_sprites), r_vertices, -1):
			delete_vertex('r')
	
	# handle left vertices
	if l_difference > 0:
		for i in range(len(l_sprites), l_vertices):
			add_vertex(i, Vector2(LEFT_COLUMN, TOP + VERTEX_SPACE + VERTEX_SPACE * i))
	if l_difference < 0:
		for _i in range(len(l_sprites), l_vertices, -1):
			delete_vertex('l')

func _input_changed(string, which):
	# is new value integer?
	if not string.is_valid_integer():
		if which:
			r_input.text = ''
		else:
			l_input.text = ''
		return
	var n = int(string)
	
	# is it in range?
	if n > 10 or n < 0:
		if which:
			r_input.text = ''
		else:
			l_input.text = ''
		return
	
	# update value
	if which:
		r_vertices = n
	else:
		l_vertices = n

# reset 'grabbed' vertex on mouse up
func _process(delta):
	if Input.is_action_just_pressed('enter'):
		update()
		
	if Input.is_action_just_pressed('del'):
		for connection in connections:
			connection[2].set_texture(line_texture)
		
	if grabbed != null:
		if not Input.is_action_pressed('left_click'):
			grabbed = null

func get_edges():
	return edges
	
func launch(matching):
	for edge in matching:
		connections[edges.find(edge)][2].set_texture(match_texture) #nonsense here
	#var json_data = JSON.print(matching)
	#print('data: ', JSON.parse(json_data).result)

