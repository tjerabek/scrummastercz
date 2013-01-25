# Index routes

mongoose = require 'mongoose'

db = mongoose.createConnection 'localhost', 'test'

schema = mongoose.Schema { 
	name: { type: 'string' }, 
	state: { type: 'Number', default: 1 }, 
	isRemoved: { type: 'Boolean', default: false }, 
	isDeleted: { type: 'Boolean', default: false },
	projectId: { type: 'ObjectId' },
	hashtags: { type: Array, default: [] } 
}

Task = db.model('Task', schema)

projectSchema = mongoose.Schema {
	name: { type: 'string' },
	isPublic: { type: 'Boolean' },
	hash: { type: 'string', index: { unique: true, dropDups: true } }
	email: { type: 'string', index: true }
}

Project = db.model('Project', projectSchema)

Hashids = require("hashids")
hashids = new Hashids("tohle je muj scrum project");

exports.index = (req, res) ->
	if req.user?
		res.render 'index', { email: req.user.email, name: req.user.name }
	else 
		res.render 'index', { email: '', name: '' }

exports.todo = (req, res) ->
	if req.params.project?
		email = ''
		if req.user?
			email = req.user.email

		Project.findOne { hash: req.params.project, $or : [{ email: email }, { email: '' }] }, (err, project) ->
			if project
				console.log err if err

				if req.params.tag? and req.params.tag isnt ''
					Task.find { state: 1, projectId: project._id, hashtags: { $in : [req.params.tag] }  }, (err, tasks) ->
						res.json(tasks)
				else 
					Task.find { state: 1, projectId: project._id  }, (err, tasks) ->
						res.json(tasks)
			else
				res.json([])
	else
		res.json([])

exports.inprogress = (req, res) ->
	if req.params.project?

		email = ''
		if req.user?
			email = req.user.email

		Project.findOne { hash: req.params.project, $or : [{ email: email }, { email: '' }] }, (err, project) ->
			if project
				console.log err if err
				if req.params.tag? and req.params.tag isnt ''
					Task.find { state: 2, projectId: project._id, hashtags: { $in : [req.params.tag] }  }, (err, tasks) ->
						res.json(tasks)
				else 
					Task.find { state: 2, projectId: project._id  }, (err, tasks) ->
						res.json(tasks)
			else
				res.json([])
	else
		res.json([])

exports.done = (req, res) ->
	if req.params.project?

		email = ''
		if req.user?
			email = req.user.email

		Project.findOne { hash: req.params.project, $or : [{ email: email }, { email: '' }] }, (err, project) ->
			if project
				console.log err if err
				if req.params.tag? and req.params.tag isnt ''
					Task.find { state: 3, projectId: project._id, hashtags: { $in : [req.params.tag] }  }, (err, tasks) ->
						res.json(tasks)
				else 
					Task.find { state: 3, projectId: project._id  }, (err, tasks) ->
						res.json(tasks)
			else
				res.json([])
	else
		res.json([])

exports.save = (req, res) ->
	email = ''
	if req.user?
		email = req.user.email

	Project.findOne { hash: req.params.project, $or : [{ email: email }, { email: '' }] }, (err, project) ->
		hashtags = findHashtags(req.body.name)
		newTask = new Task { name: req.body.name, state: 1, isRemoved: false, isDeleted: false, projectId: project._id, hashtags: hashtags }
		newTask.save (err) ->
			console.log err if err
		
			res.json({ id: newTask._id, name: req.body.name, hashtags: hashtags })

exports.makeInProgress = (req, res) ->
	Task.findOne { _id: req.body.id }, (err, task) ->
		task.state = 2
		task.save (err) ->
			console.log err if err
			res.json({})

exports.makeDone = (req, res) ->
	Task.findOne { _id: req.body.id }, (err, task) ->
		task.state = 3
		task.save (err) ->
			console.log err if err
			res.json({})

exports.makeTodo = (req, res) ->
	Task.findOne { _id: req.body.id }, (err, task) ->
		task.state = 1
		task.save (err) ->
			console.log err if err
			res.json({})

exports.remove = (req, res) ->
	Task.findOne { _id: req.body.id }, (err, task) ->
		task.remove (err) ->
			console.log err if err
			res.json({})

exports.info = (req, res) ->
	if req.params.project?
		email = ''
		if req.user?
			email = req.user.email

		Project.findOne { hash: req.params.project, $or : [{ email: email }, { email: '' }] }, (err, project) ->
			if project
				res.json({ Exists: true, name: project.name })
			else
				res.json({ Exists: false })
	else
		res.json({ Exists: false })

exports.createProject = (req, res) ->
	if req.body.name? and req.body.name isnt ''

		hash = hashids.encrypt(new Date().valueOf())

		userEmail = ''
		if req.user? and req.body.ispersonal
			userEmail = req.user.email 

		newProject = new Project({ name: req.body.name, isPublic: true, hash: hash, email: userEmail })
		console.log newProject
		
		newProject.save (err) ->
			console.log err if err

			txt = "Drag me to change my state."
			hashtags = findHashtags(txt)
			newTask = new Task { name: txt, state: 1, isRemoved: false, isDeleted: false, projectId: newProject._id, hashtags: hashtags }
			newTask.save (err) ->
				console.log err if err

				txt = "Filter tasks like me using #hashtags"
				hashtags = findHashtags(txt)
				newTask = new Task { name: txt, state: 2, isRemoved: false, isDeleted: false, projectId: newProject._id, hashtags: hashtags }
				newTask.save (err) ->
					console.log err if err

					txt = "You can edit or delete me. #hashtags"
					hashtags = findHashtags(txt)
					newTask = new Task { name: txt, state: 3, isRemoved: false, isDeleted: false, projectId: newProject._id, hashtags: hashtags }
					newTask.save (err) ->
						console.log err if err
						res.json({ hash: hash })

exports.update = (req, res) ->
	Task.findOne { _id: req.body.id }, (err, task) ->
		task.name = req.body.name
		task.hashtags = findHashtags req.body.name
		task.save (err) ->
			console.log err if err
			res.json({})

exports.projects = (req, res) ->
	if req.user?
		Project.find { email: req.user.email }, (err, projects) ->
			res.json(projects)
	else
		res.json({})

# Pomocna funkce na hledani tagu

findHashtags = (txt) ->
	tags = txt.match(/(#[A-Za-z0-9\-\_]+)/g) or []
	outTags = []
	for tag in tags
		outTags.push(tag.replace(/\#/g,''))
	return outTags

exports.dashboard = (req, res) ->
	res.render 'dashboard', { email: req.user.email, name: req.user.name }