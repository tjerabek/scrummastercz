window.ScrumCtrl = ($scope, $location, $http) ->
	$scope.newProjectForm = false
	$scope.newTaskForm = false
	$scope.newTaskText = ""
	$scope.todos = []
	$scope.inprogress = []
	$scope.dones = []
	$scope.exists = true
	$scope.newProjectName = ""
	$scope.newProjectEmptyName = false
	$scope.newProjectLoading = false
	$scope.projectName = ""
	$scope.hashFilter = ""
	$scope.ispersonal = false
	$scope.projects = []
	$scope.projectCreated = false
	$scope.projectHash = ""
	
	toRemove = new Array()
	
	$http.get('info.json').success (data)->
		$scope.exists = data.Exists
		$scope.projectName = data.name
	
	$http.get('todo.json').success (data) ->
		for item in data
			item.tokens = tokenize item.name
		$scope.todos = data
	
	$http.get('inprogress.json').success (data) ->
		for item in data
			item.tokens = tokenize item.name
		$scope.inprogress = data

	$http.get('done.json').success (data)->
		for item in data
			item.tokens = tokenize item.name
		$scope.dones = data

	$http.get('projects.json').success (data)->
		$scope.projects = data
	
	$scope.newProject = () ->
		$scope.newProjectForm = true

	$scope.newPersonalProject = () ->
		$scope.newProjectForm = true
		$scope.ispersonal = true
	
	$scope.cancelNewProject = () ->
		$scope.newProjectForm = false
		$scope.ispersonal = false
	
	$scope.newTask = () ->
		$scope.newTaskForm = true
		pos = findPosition(document.getElementById('new-task'))
		
		window.scrollTo(pos[0], pos[1])
	
		setTimeout(() ->
			document.getElementById('new-task-textarea').focus()
		, 1)
	
	$scope.cancelNewTask = () ->
		$scope.newTaskForm = false
	
	$scope.addTask = () ->
		if $scope.newTaskText
			$http.post('save', { name: $scope.newTaskText }).success (data) ->
				tokens = tokenize data.name
				$scope.todos.push({ name: data.name, _id: data.id, tokens: tokens })
		
		$scope.newTaskText = ""
		$scope.newTaskForm = false
	
	$scope.makeInProgress = (task) ->
		if $scope.inprogress.indexOf(task) is -1
			$scope.todos.splice $scope.todos.indexOf(task), 1 if $scope.todos.indexOf(task) > -1
			$scope.dones.splice $scope.dones.indexOf(task), 1 if $scope.dones.indexOf(task) > -1
			$scope.inprogress.push task
			$http.post('makeInProgress', { id: task._id })
	
	$scope.makeDone = (task) ->
		if $scope.dones.indexOf(task) is -1
			$scope.todos.splice $scope.todos.indexOf(task), 1 if $scope.todos.indexOf(task) > -1
			$scope.inprogress.splice $scope.inprogress.indexOf(task), 1 if $scope.inprogress.indexOf(task) > -1
			$scope.dones.push task
			$http.post('makeDone', { id: task._id })
	
	$scope.makeTodo = (task) ->
		if $scope.todos.indexOf(task) is -1
			$scope.dones.splice $scope.dones.indexOf(task), 1 if $scope.dones.indexOf(task) > -1
			$scope.inprogress.splice $scope.inprogress.indexOf(task), 1 if $scope.inprogress.indexOf(task) > -1
			$scope.todos.push task
			$http.post('makeTodo', { id: task._id })
	
	$scope.removeTask = (task) ->
		task.isRemoved = true
		$http.post('remove', { id: task._id })
		
		setTimeout(() ->
			angular.forEach $scope.todos, (item) ->
				if item.isRemoved
					index = $scope.todos.indexOf(item)
					$scope.todos.splice index, 1 if index > -1
			
			angular.forEach $scope.inprogress, (item) ->
				if item.isRemoved
					index = $scope.inprogress.indexOf(item)
					$scope.inprogress.splice index, 1 if index > -1
			
			angular.forEach $scope.dones, (item) ->
				if item.isRemoved
					index = $scope.dones.indexOf(item)
					$scope.dones.splice index, 1 if index > -1
			
			$scope.$digest()
		, 300)
	
	$scope.updateTaskSave = (task) ->
		task.editing = false
		task.tokens = tokenize task.name
		$http.post('update', { id: task._id, name: task.name })
	
	$scope.updateTask = (task) ->
		task.editing = true
	
		setTimeout(() ->
			textareas = document.getElementsByTagName("textarea")
	
			for textarea in textareas
				sH = textarea.scrollHeight
				cH = textarea.offsetHeight
				if sH > 0 and cH > 0
					textarea.style.height = sH + 'px'
					
		, 1)
	
	$scope.cancelEditing = (task) ->
		task.editing = false
		
	$scope.transfered = {}
	
	$scope.transfer = (task) ->
		$scope.transfered = task
	
	$scope.dropProgress = () ->
		$scope.makeInProgress $scope.transfered
	
	$scope.dropTodo = () ->
		$scope.makeTodo $scope.transfered
	
	$scope.dropDone = () ->
		$scope.makeDone $scope.transfered
	
	$scope.createNewProject = () ->
		if $scope.newProjectName is ''
			$scope.newProjectEmptyName = true
		else
			$scope.newProjectLoading = true
			
			$http.post('create-project', { name: $scope.newProjectName, ispersonal: $scope.ispersonal }).success (data) ->
				$scope.newProjectLoading = false
				# $scope.exists = true
				$scope.projectName = $scope.newProjectName
				$scope.projectCreated = true
				$scope.projectHash = data.hash
				# window.location = "/"+data.hash+"/"

	$scope.filterByHash = (hash) ->
		$scope.hashFilter = hash
		$http.get('' + hash.replace(/\#/g,'')+'/todo.json').success (data) ->
			for item in data
				item.tokens = tokenize item.name
			$scope.todos = data
		
		$http.get('' + hash.replace(/\#/g,'')+'/inprogress.json').success (data) ->
			for item in data
				item.tokens = tokenize item.name
			$scope.inprogress = data

		$http.get('' + hash.replace(/\#/g,'')+'/done.json').success (data) ->
			for item in data
				item.tokens = tokenize item.name
			$scope.dones = data

	$scope.removeTagFilter = () ->
		$scope.hashFilter = ''
		$http.get('todo.json').success (data) ->
			for item in data
				item.tokens = tokenize item.name
			$scope.todos = data
		
		$http.get('inprogress.json').success (data) ->
			for item in data
				item.tokens = tokenize item.name
			$scope.inprogress = data

		$http.get('done.json').success (data) ->
			for item in data
				item.tokens = tokenize item.name
			$scope.dones = data

	$scope.toggleProjectState = () ->
		$scope.ispersonal = !$scope.ispersonal

module = angular.module('scrumModule', [])

module.directive 'drag', ->
	{ link: (scope, element, attrs) ->
		element.bind 'dragstart', ->
			scope.$apply attrs.drag
	}

module.directive 'drop', ->
	{ link: (scope, element, attrs) ->
		element.bind 'drop', ->
			scope.$apply attrs.drop
	}

window.allowDrop = (ev) ->
	ev.preventDefault()

window.drag = (ev) ->
	ev.dataTransfer.setData 'Text', ev.target.id

findPosition = (obj) ->
	curleft = curtop = 0;
	if obj.offsetParent
		curleft = obj.offsetLeft
		curtop = obj.offsetTop
	
		while obj = obj.offsetParent
			curleft += obj.offsetLeft
			curtop += obj.offsetTop
	
	return [curleft,curtop];

findHashtags = (txt) ->
	return txt.match(/(#[A-Za-z0-9\-\_]+)/g) or []

isHash = (txt) ->
	return findHashtags(txt).length > 0

replaceAllTags = (tags, txt) ->
	for tag in tags
		txt = txt.replaceAll(tag, '<a href="" ng-click="filterByTag()">'+tag+'</a>')
	return txt

tokenize = (data) ->
	tokensValues = data.replace(/\n/g, ' ').split(' ')
	tokens = []

	for token in tokensValues
		tokens.push({ value: token, isHash: isHash(token) })

	return tokens

String.prototype.replaceAll = (stringToFind, stringToReplace) ->
	this.split(stringToFind).join(stringToReplace)
