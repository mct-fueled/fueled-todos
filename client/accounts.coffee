#
# Client-side logging in
#

Template.user_loginform.events(
	'click #login': loginFn

)

loginFn = (e) ->
	e.preventDefault()
	Meteor.loginWithTwitter({}, (err) ->
		if(err)
			Session.set('errorMessage', err.reason || "Unknown error")
	)