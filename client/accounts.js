//
// Client-side logging in
//

Template.user_loginform.events({
	'click #login': loginFn
});

Template.todosHeader.events({
	'click .btn--logout': logoutFn
});

function loginFn(e) {
	e.preventDefault();
	Meteor.loginWithTwitter({}, function (err) {
		if(err) {
			Session.set('errorMessage', err.reason || "Unknown error")
		} else {
			Session.set('user_id', Meteor.userId());
			Session.set('username', Meteor.user().profile.name);
			UserBase.insert({
				user_id: Meteor.userId,
				name: Meteor.user().profile.name
			});
		}
	});
}

function logoutFn(e) {
	e.preventDefault();
	Meteor.logout(function(err) {
		if(err) {
			Session.set('errorMessage', err.reason || "Unknown error")
		} else {
			Session.set('user_id', null);
			Session.set('username', null);
		}
	});
}