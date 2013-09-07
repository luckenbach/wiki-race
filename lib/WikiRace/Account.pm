package WikiRace::Account;
use lib '..';
use Helper;
use Mojo::Base 'Mojolicious::Controller';
use Data::Dumper;
sub register {
	my $self = shift;

	my $username = $self->param('username');
	my $email    = $self->param('email');
	my $pass     = $self->param('pass');
	my $pass2    = $self->param('pass2');


	$log->info("username : $username : email $email : pass : $pass : pass2 : $pass2");
	if ($pass !~ m{^$pass2$}) {
		$self->flash(error => "passwords don't match!");
		return $self->redirect_to('/login#Register');
	}


	# search to see if username is unique before inserting
	my $exists = $users->find({ username => $username })->count;
	if ($exists > 0) {
		$self->flash(error => "username already exists - please try again");
		return $self->redirect_to('/login#Register');
	}

	my $user_id = $users->insert({
		username => $username,
		email => $email,
		pass => $self->bcrypt($pass),
		joined => time(),
	});

	$self->session( user_id => $user_id->to_string );
	$self->session( username => $username );

	$self->redirect_to('/');
}



1;
