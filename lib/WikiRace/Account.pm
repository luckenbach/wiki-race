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
	
	if(!$username) {
		$self->flash(error => "No username defined");
		return $self->redirect_to('/login#Register');
	}

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

sub account {
	my $self = shift;

	my %user_details;

	my $id    = MongoDB::OID->new( value => $self->session('user_id') );

	my $user = $users->find({ _id => $id });
	if (my $doc = $user->next) {
		$user_details{'email'}    = $doc->{'email'};
		$user_details{'name'}     = $doc->{'name'};
	} else {
		return $self->render_exception("user not found");
	}

	$self->render(user_details => \%user_details);
}


sub update {
	my $self = shift;
	my $res = $users->find({ _id => MongoDB::OID->new(value=> $self->session('user_id'))});
#	my $pass = $self->bcrypt($self->param('pass'));
	my $pass = $self->param('pass');
	my $doc = $res->next;
	unless($self->bcrypt_validate($pass, $doc->{"pass"})) {
		$self->flash(error => "You password did not match what was on file");
		$self->redirect_to('/account');
	}
	my $new_email   	= $self->param('email') || $doc->{'email'};;
	my $new_pass     	= $self->param('pass');
	my $new_pass2    	= $self->param('pass2');
	if($self->param('new_pass') ) {
		my $new_pass = $self->bcrypt($self->param('new_pass'));
	} else {
		my $new_pass = $doc->{'pass'};
	}
       	my $exists = $users->find({ email => $new_email })->count;
        if ($exists > 0) {
                $self->flash(error => "email already in use");
                return $self->redirect_to('/account');
        }
	if ($new_pass !~ m{^$new_pass2$}) {
		$self->flash(error => "new passwords don't match!");
		return $self->redirect_to('/account');
	}

	$users->update({ _id => MongoDB::OID->new(value=> $self->session('user_id'))}, {'$set' => { 'email' => $new_email, 'pass' => $new_pass}});
	$self->flash( message => "Account has been updated" );
	$self->redirect_to('/account');
}




1;
