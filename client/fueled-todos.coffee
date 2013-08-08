# Define collections
Lists = new Meteor.Collection("lists")
Todos = new Meteor.Collection("todos")

#
# Router
#

TodosRouter = Backbone.Router.extend(
	routes:
		":list_id" : "main"
		":person_id":	"viewPerson"

	main: (list_id) ->
		oldList = Session.get("list_id")
		if(oldList is not list_id)
			Session.set('list_id', list_id)
			Session.set('person_id', null)
			Session.set('tag_filter', null)

	viewPerson: (person_id) ->
		oldPerson = Session.get('person_id')
		if(oldPerson is not person_id)
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
	if(!list_id)
		`return {}`

	sel =
		list_id: list_id
	tag_filter = Session.get('tag_filter')
	if(tag_filter)
		sel.tags = tag_filter

	Todos.find(
		sel
		sort:
			timestamp: 1
	)
