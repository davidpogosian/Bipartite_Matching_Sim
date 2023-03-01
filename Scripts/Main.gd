extends Node

# textures for dots
var green_dot = preload('res://Textures/green_dot.png')
var black_dot = preload('res://Textures/black_dot.png')
var blue_dot = preload('res://Textures/tickmark.png')

# prefabs
var dot = preload('res://Prefabs/Dot.tscn')
var panel = preload('res://Prefabs/Panel.tscn')
var button = preload('res://Prefabs/Button.tscn')
var button2 = preload('res://Prefabs/Button2.tscn')
var disappearing = preload('res://Prefabs/Disappearing_Button.tscn')

var MAX_VERTICES = 10
var PANEL_SPREAD = 600
var PANEL_SHIFT = 500

var panels = []
var first_panel = null
func _ready():
	# graph
	for i in range(20):
		make_dot(Vector2(i * 20, 0), black_dot)
		make_dot(Vector2(0, i * 20), black_dot)
	
	# run button
	var submit_button = button2.instance()
	submit_button.set_text('Launch')
	submit_button.set_position(Vector2(0, -50))
	submit_button.connect('pressed', self, 'run')
	add_child(submit_button)
	
	# first panel
	first_panel = panel.instance()
	first_panel.set_algorithm('david')
	panels.append(first_panel)
	first_panel.set_position(Vector2(PANEL_SHIFT, 0))
	add_child(first_panel)
	
	var algorithms = ['hopcroft_karp', 'augmenting-path']
	# subsequent panels:
	for i in range(2):
		var add_button = disappearing.instance()
		add_button.set_algo(algorithms[i])
		add_button.set_position(Vector2(PANEL_SHIFT + PANEL_SPREAD * i + PANEL_SPREAD, 0))
		add_child(add_button)

func make_dot(pos, texture):
	var new_dot = dot.instance()
	new_dot.get_node("Sprite").set_texture(texture)
	new_dot.set_position(pos)
	add_child(new_dot)

func new_panel(algo, pos):
	var new_panel = panel.instance()
	new_panel.set_algorithm(algo)
	new_panel.set_position(pos)
	new_panel.copy_panel(first_panel)
	panels.append(new_panel)
	add_child(new_panel)

func run():
	for panel in panels:
		var edges = null
		var algo = panel.get_algorithm()
		if algo == 'hopcroft_karp':
			edges = hopcroft_karp(panel.get_edges(), panel.get_u(), panel.get_v())

			# graph output
			for edge in panel.get_edges():
				if edge in edges:
					make_dot(Vector2(edge[0] * 20, edge[1] * 20), green_dot)
				else:
					make_dot(Vector2(edge[0] * 20, edge[1] * 20), blue_dot)

		if algo == 'david':
			edges = david(panel.get_edges())
			
		if algo == 'augmenting-path':
			var U = []
			var W = []
			for u in range(panel.get_u()):
				U.append(u)
			for w in range(MAX_VERTICES, panel.get_v() + MAX_VERTICES):
				W.append(w)
			edges = augmenting_path(panel.get_edges(), U, W)
		panel.launch(edges)

# augmenting path algo
func deep_copy(from, to):
	for item in from:
		to.append(item)

func augmenting_path(edges, vertices_u, vertices_w):
	var free_u = []
	var free_w = []
	deep_copy(vertices_u, free_u)
	deep_copy(vertices_w, free_w)
	
	var M = []
	var P = find_aug_path(edges, M, free_u, free_w)
	while (P != null):
		M = symmetric_difference(M, P)
		
		for edge in M:
			if edge[0] in free_u:
				free_u.erase( edge[0] )
			if edge[1] in free_w:
				free_w.erase( edge[1] )
		
		P = find_aug_path(edges, M, free_u, free_w)
	return M

func find_aug_path(edges, M, free_u, free_w):
	var bfs_edges = []
	for edge in edges:
		if edge in M:
			bfs_edges.append( [edge[1], edge[0]] )
		else:
			bfs_edges.append( edge ) # this had to be swapped for some reason
	for u in free_u:
		bfs_edges.append( [-1, u] )
	for w in free_w:
		bfs_edges.append( [w, -2] )
	return bfs_path(bfs_edges, -1, -2)

func symmetric_difference(M, P):
	for edge in P:
		if not edge in M:
			M.append(edge)
		else:
			M.erase(edge)
	# even though arrays are passed by reference, I just wanna return
	return M

func bfs_path(edges, s, t):
	var neighbors = {} # neighbors[start] = [end]
	# setting up neighbors dict
	for edge in edges:
		if edge[0] in neighbors:
			neighbors[ edge[0] ].append( edge[1] )
		else:
			neighbors[ edge[0] ] = [ edge[1] ]
	
	var queue = [s]
	var parentof = {}
	var found = false
	
	while len(queue) != 0:
		#break
		var current = queue[0]
		if current == t:
			found = true
			break
		queue.pop_front()
		if not current in neighbors:
			continue
		for neighbor in neighbors[current]:
			if not neighbor in parentof:
				queue.push_back(neighbor)
				parentof[neighbor] = current
	if found:
		var steps = []
		var current = t
		while parentof[current] != s:
			steps.append(parentof[current])
			current = parentof[current]
		
		var P = []
		for i in range(len(steps) - 1):
			if steps[i] < steps[i + 1]:
				P.append( [steps[i], steps[i + 1]] )
			else:
				P.append( [steps[i + 1], steps[i]] )
				
		return P
		
	return null

# this algorithm operates on the assumption that if you have a completed
# matching one of them is between the highest vertex and the lowest connected vertex
# approximation algo at best
func vertex_compare(a, b):
	if b[1] <= a[1]:
		return true
	return false

func david(edges):
	var answer = []
	#print('EDGES ', edges)
	var vertex_ranks = {} # [index, number_of_edges]
	for edge in edges:
		if edge[0] in vertex_ranks:
			vertex_ranks[edge[0]] += 1
		else:
			vertex_ranks[edge[0]] = 1
			
		if edge[1] in vertex_ranks:
			vertex_ranks[edge[1]] += 1
		else:
			vertex_ranks[edge[1]] = 1
	#print('DICT: ', vertex_ranks)
	var keys = vertex_ranks.keys()
	var values = vertex_ranks.values()
	var array = []
	for k in range(len(keys)):
		array.append([keys[k], values[k]])
	#print(array)
	array.sort_custom(self, 'vertex_compare')
	#print('ARRAY: ', array)
	
	# go through array
	# find lowest-ranked vertex that is connected to first vertex
	# get rid of those vertices in array
	# pop off first
	while len(edges) != 0:
		# re calculate
		vertex_ranks = {} # [index, number_of_edges]
		for edge in edges:
			if edge[0] in vertex_ranks:
				vertex_ranks[edge[0]] += 1
			else:
				vertex_ranks[edge[0]] = 1
				
			if edge[1] in vertex_ranks:
				vertex_ranks[edge[1]] += 1
			else:
				vertex_ranks[edge[1]] = 1
		#print('DICT: ', vertex_ranks)
		keys = vertex_ranks.keys()
		values = vertex_ranks.values()
		array = []
		for k in range(len(keys)):
			array.append([keys[k], values[k]])
		#print(array)
		array.sort_custom(self, 'vertex_compare')
		
		#print('===========================')
		var special = array[0][0]
		var min_vertex = null
		var min_edges = 9_999
		var best_edge = null
		for edge in edges:
			if special in edge:
				if edge[0] == special:
					if vertex_ranks[edge[1]] < min_edges:
						min_vertex = edge[1]
						min_edges = vertex_ranks[edge[1]]
						best_edge = edge
				
				if edge[1] == special:
					if vertex_ranks[edge[0]] < min_edges:
						min_vertex = edge[0]
						min_edges = vertex_ranks[edge[0]]
						best_edge = edge
		
		if best_edge == null:
			# get rid of vertices
			array.pop_front()
			
			# should be no edges left to it....
			var temp_edges = []
			for edge in edges:
				if special in edge:
					#print('removing edge')
					pass
				else:
					temp_edges.append(edge)
			edges = temp_edges
			
			continue
			
		# min vertex found
		answer.append(best_edge)
		#print('BEST EDGE: ', best_edge)
		
		# get rid of vertices
		var temp_array = []
		for entry in array:
			if best_edge[0] == entry[0] or best_edge[1] == entry[0]: # invalid index 0 on base 'Nil'
				pass
			else:
				temp_array.append(entry)
		array = temp_array
		var temp_edges = []
		for edge in edges:
			if best_edge[0] in edge or best_edge[1] in edge:
				pass
			else:
				temp_edges.append(edge)
		edges = temp_edges
		
		#print('NEW EDGES: ', edges)
		#print('NEW ARRAY: ', array)
	#print('ANSWER:', answer)  
	
	return answer

# Hopcroft-Karp Algo (not really)
func hopcroft_karp(free_edges, u_vertices: int, v_vertices: int):
	print('hopcroft-karp running...')
	var original_edges = []
	for edge in free_edges:
		original_edges.append(edge)
	var free_u = range(u_vertices)
	var free_v = range(MAX_VERTICES, MAX_VERTICES + v_vertices) # 10 is max vertices
	var used_u = []
	var used_v = []
	var matched_edges = []
	# make initial matchings
	
	for u in free_u:
		
		var matched_v = null
		
		for edge in free_edges:
			if u in edge:
				
				# move u to used, move edge to matched
				used_u.append(u)
				matched_edges.append(edge)
				
				# move v to used
				matched_v = edge[0]
				if u == edge[0]:
					matched_v = edge[1]
					
				used_v.append(matched_v)
				
				# remove v from free
				#print('u: ', u, ' removed v:', matched_v)
				free_v.erase(matched_v)
				
				break
		
		# remove edges that contain v from free		
		if matched_v != null:
			var new_free_edges = []
			for edge in free_edges:
				if not matched_v in edge:
					new_free_edges.append(edge)
			free_edges = new_free_edges
	
	# remove u from free
	for u in used_u:
		free_u.erase(u)
	
	# RIGGING:
#	matched_edges = [[0, 10], [16, 1], [2, 11], [15, 4], [5, 12]]
#	free_u = [3, 6]
#	free_v = [13, 14]
#	used_u = []
#	used_v = []
#	for i in range(7):
#		if not i in free_u:
#			used_u.append(i)
#		if not i+10 in free_v:
#			used_v.append(i+10)
	
	# reset free edges!
	free_edges = []
	for edge in original_edges:
		free_edges.append(edge)
	for edge in matched_edges:
		free_edges.erase(edge)
	
	
	# DEBUG #1
	#print('OG: ', original_edges)
	#print('free_u: ', free_u)
	#print('used_u: ', used_u)
	#print('free_v: ', free_v)
	#print('used_v: ', used_v)
	#print('matched_edges: ', matched_edges)
	#print('free_edges: ', free_edges)
	
	# look for augmenting paths BFS (queue) =====================
	
	
	
	# check if all vertices matched
	if len(free_u) == 0:
		print('answer: ', matched_edges)
		return matched_edges
		
	var queue = []
	var memory = []
	var visited = []
	var terminate = false
	
	for u in free_u:
		queue.append(u)
	
	# initialize hash map for path tracing, and visited
	for i in range(MAX_VERTICES * 2):
		memory.append([])
		visited.append(false)
		
	while len(queue) != 0:
		#print('at: ', queue[0])
		
		# mark current vertex visited
		visited[queue[0]] = true
		
		# check if vertix is in U or V
		var available_edges = free_edges if queue[0] < MAX_VERTICES else matched_edges
		
		#print('available edges: ', available_edges)
		
		# follow free edges
		for edge in available_edges:
			if queue[0] in edge:
				#print('following: ', edge)
				
				var next_vertex = null
				
				if queue[0] == edge[0]:
					next_vertex = edge[1]
				else:
					next_vertex = edge[0]
				
				# if visited move on
				if visited[next_vertex]:
					continue
				
				memory[next_vertex].append(queue[0])
				
				# check if next_vertex in free_v
				if next_vertex in free_v:
					# stop at this layer
					terminate = true
				
				if not terminate:
					queue.append(next_vertex)
		
		queue.pop_front()
		
	# figure out which edges to switch around
	
	#print('memory: ', memory)
	
	#print('terminate: ', terminate)
	
	if not terminate:
		return matched_edges
		
	# DFS up memory from free_v to free_u
	visited = []
	for i in range(MAX_VERTICES * 2):
		visited.append(false)
	
	for v in free_v:
		
		var found = false
		var path = []
		for i in range(MAX_VERTICES * 2):
			path.append(null)
		var stack = [v]
		
		while len(stack) != 0:
			var vertex = stack.back() 
			visited[vertex] = true
			stack.pop_back()
			
			for option in range(len(memory[vertex])):
				if visited[memory[vertex][option]]: # cant have the [0]
					continue
					
				stack.append(memory[vertex][option])
				# keep track of parents
				#path[memory[vertex][0]] = vertex
				path[vertex] = memory[vertex][option]
				
				if memory[vertex][option] in free_u:
					found = true
					break
		
		#print('path: ', path)
		
		if found:
			# remove path from memory		
			for i in range(len(memory)):
				if path[i] in memory[i]:
					memory[i].erase(path[i])
					
			# invert edges
			var start = v
			var end = path[v]
			while end != null:
				
				#print('invert edge: ', start, ' ', end)
				
				# edge [start, end]
				var flip_edge = [start, end] if [start, end] in original_edges else [end, start]
				
				if flip_edge in free_edges:
					free_edges.erase(flip_edge)
					matched_edges.append(flip_edge)
				elif flip_edge in matched_edges:
					matched_edges.erase(flip_edge)
					free_edges.append(flip_edge)
				
				start = end
				end = path[end]
	#print('answer2: ', matched_edges)
	return matched_edges
