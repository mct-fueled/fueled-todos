# Define collections
Lists = new Meteor.Collection("lists")
Todos = new Meteor.Collection("todos")
People = new Meteor.Collection("people")

#
# Set Defaults
#

Session.setDefault('list_id', null)
Session.setDefault('person_id', null)
Session.setDefault('tag_filter', null)
Session.setDefault('editing_addtag', null)
Session.setDefault('editing_listname', null)
Session.setDefault('editing_itemname', null)

#
# Startup Code
#

listsHandle = ->
	Meteor.subscribe(
		'lists'
		->
			if !Session.get('list_id')
				list = Lists.findOne({},
					sort:
						name: 1
				)
				if list
					Router.setList(list._id)

	)

todosHandle = null

Deps.autorun ->
		list_id = Session.get('list_id')
		if list_id
			todosHandle = Meteor.subscribe('todos', list_id)
		else
			todosHandle = null


okCancelEvents = (selector, callbacks) ->
	ok = callbacks.ok || `function(){}`
	cancel = callbacks.cancel || `function(){}`
	events = {}
	events['keyup '+selector+', keydown '+selector+', focusout '+selector] = (evt) ->
		if evt.type is "keydown" and evt.which is 27
			cancel.call(this, evt)
		else if evt.type is "keyup" and evt.which is 13 or evt.type is "focusout"
			value = String(evt.target.value or "")
			if value
				ok.call(this, value, evt)
			else
				cancel.call(this, evt)
		undefined
	events

activateInput = (input) ->
	input.focus()
	input.select()


#
# Router
#

TodosRouter = Backbone.Router.extend(
	routes:
		":list_id" : "main"
		":person_id":	"viewPerson"

	main: (list_id) ->
		oldList = Session.get("list_id")
		if oldList is not list_id
			Session.set('list_id', list_id)
			Session.set('person_id', null)
			Session.set('tag_filter', null)

	viewPerson: (person_id) ->
		oldPerson = Session.get('person_id')
		if oldPerson is not person_id
			Session.set('person_id', person_id)
			Session.set('list_id', null)
			Session.set('tag_filter', null)

	setList: (list_id) ->
		@navigate(list_id, true)

	setPerson: (person_id) ->
		@navigate(person_id, true)
)

Router = new TodosRouter

Meteor.startup ->
	Backbone.history.start pushState:true

#
# User
#

Template.todosHeader.fullName = ->
	Meteor.user().profile.name

#
# Lists
#

Template.lists.loading = ->
	!listsHandle.ready()

Template.lists.lists = ->
	Lists.find({},
		sort:
			name: 1
	)

Template.lists.events ->
	'mousedown .list': (evt) ->
		Router.setList @_id
	'click .list': (evt) ->
		evt.preventDefault()
	'dblclick .list': (evt, tmpl) ->
		Session.set 'editing_listname', @_id
		Deps.flush()
		activateInput tmpl.find('#js--list-name-input')

Template.lists.events okCancelEvents('js--new-list',
	ok: (text, evt) ->
		id = Lists.insert name: text
		Router.setList id
		evt.target.value = ""
)

Template.lists.events okCancelEvents('#js--list-name-input',
	ok: (value) ->
		Lists.update @_id,
			$set:
				name: value

		Session.set "editing_listname", null

	cancel: ->
		Session.set "editing_listname", null
)

Template.lists.selected = ->
	(if Session.equals('list_id', @_id) then "selected" else "")

Template.lists.name_class = ->
	(if @name then "" else "empty")

Template.lists.editing = ->
	Session.equals('editing_listname', @_id)

#
# Todos
#

Template.todos.loading = ->
	todosHandle and !todosHandle.ready()

Template.todos.any_list_selected = ->
	!Session.equals('list_id', null)

Template.todos.events okCancelEvents('#js--new-todo',
	ok: (text, evt) ->
		tag = Session.get("tag_filter")
		Todos.insert
			text: text
			list_id: Session.get("list_id")
			done: false
			timestamp: (new Date()).getTime()
			tags: (if tag then [tag] else [])

		evt.target.value = ""

Template.todos.todos = ->
	list_id = Session.get('list_id')
	person_id = Session.get('person_id')
	if !list_id
		`return {}`

	sel =
		list_id: list_id
	tag_filter = Session.get('tag_filter')
	if tag_filter
		sel.tags = tag_filter

	Todos.find(
		sel
		sort:
			timestamp: 1
	)

#
# Todo Item
#

Template.todo_item.tag_objs = ->
	todo_id = @_id
	_.map @tags or [], (tag) ->
		todo_id: todo_id
		tag: tag

Template.todo_item.done_class = ->
	(if @done then 'done' else '')

Template.todo_item.done_checkbox = ->
	(if @done then 'checked="checked"' else '')

Template.todo_item.editing = ->
	Session.equals('editing_itemname', @_id)

Template.todo_item.adding_tag = ->
	Session.equals('editing_addtag', @_id)

Template.todo_item.events ->
	'click .check': ->
		Todos.update @_id,
			$set:
				done: !@done
	'click .destroy': ->
		Todos.remove @_id
	'click .addtag': (evt, tmpl)->
		Session.set "editing_addtag", @_id
		Deps.flush()
		activateInput tmpl.find('#js--edittag-input')
	'dblclick .display .todo-text': (evt, tmpl) ->
		Session.set "editing_itemname", @_id
		Deps.flush()
		activateInput(tmpl.find('#js--todo-input'))
	'click .remove' (evt) ->
		tag = @tag
		id = @todo_id

		evt.target.parentNode.style.opacity = 0

		Meteor.setTimeout (->
			Todos.update
				_id: id
			,
				$pull:
					tags: tag

		), 300

Template.todo_item.events okCancelEvents('#js--todo-input',
	ok: (value) ->
		Todos.update @_id,
			$set:
				text: value

		Session.set 'editing_itemname', null

	cancel: ->
		Session.set 'editing_itemname', null

)

Template.todo_item.events okCancelEvents('#js--edittag-input',
	ok: (value) ->
		Todos.update @_id,
			$addToSet:
				tags: value

		Session.set 'editing_addtag', null

	cancel: ->
		Session.set 'editing_addtag', null

)

#
# Tag Filter
#

Template.tag_filter.tags = ->
	tag_infos = []
	total_count = 0

	Todos.find(list_id: Session.get('list_id')).forEach (todo) ->
		_.each todo.tags, (tag) ->
			tag_info = _.find(tag_infos, (x) -> x.tag is tag)
			unless tag_info
				tag_infos.push
					tag: tag
					count: 1

			else
				tag_info.count++

		total_count ++

	tag_infos = _.sortBy tag_infos, (x) -> x.tag
	tag_infos.unshift tag:null, count: total_count

	tag_infos

Template.tag_filter.tag_text = ->
	@tag || 'All items'

Template.tag_filter.selected = ->
	(if Session.equals "tag_filter", @tag then 'selected' else '')

Template.tag_filter.events ->
	'mousedown .tag': ->
		if Session.equals "tag_filter", @tag
			Session.set('tag_filter', null)
		else
			Session.set('tag_filter', @tag)

