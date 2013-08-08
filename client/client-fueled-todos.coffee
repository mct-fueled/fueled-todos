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
# Todos
#

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
# Todos - Events
#

`Template.todos.events(okCancelEvents(
  '#js--new-todo',
  {
    ok: function (text, evt) {
      var tag = Session.get('tag_filter');
      Todos.insert({
        text: text,
        list_id: Session.get('list_id'),
        done: false,
        timestamp: (new Date()).getTime(),
        tags: tag ? [tag] : []
      });
      evt.target.value = '';
    }
  }));`

