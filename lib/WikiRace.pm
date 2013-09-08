package WikiRace;
use Helper;
use Mojo::Base 'Mojolicious';
use Mojolicious::Plugin::Bcrypt;

# This method will run once at server start
sub startup {
	my $self = shift;

	# Documentation browser under "/perldoc"
	$self->plugin('PODRenderer');
	
	# Define the Secret
	$self->secret('f0x3a|23|)@55h0l3');

	# Setup Password crypt
	$self->plugin('bcrypt', { cost => 6});

	# Router
	my $r = $self->routes;

	# Normal route to controller
	$r->get('/')->to('core#welcome');

	$r->post('/')->to('core#start');
	
	$r->get('/getPage/*wikiPage')->to('core#getPage');
	
	$r->get('/getWLink/*wikiPage')->to('core#getWLink');

	$r->get('/challenge')->to('core#challenge');

	$r->post('/startChallenge')->to('core#startChallenge');
	
	$r->get('/shareChallenge/:caf_id')->to('core#startChallenge');
	
	$r->get('/GetHighScore')->to('highscore#getHighScore');
	
	$r->get('/personalHighScore')->to('highscore#personalHighScore');
 
	$r->post('/HighScore')->to('core#setHighScore');
	
	$r->get('/Records')->to('highscore#records');
	
	$r->get('/reset' => sub {
		my $self = shift;
		delete $self->session->{'start'};
		delete $self->session->{'finish'};
		delete $self->session->{'CAF'};
		delete $self->session->{'finish_title'};
		delete $self->session->{'count'};
		delete $self->session->{'bread_crumb'};
		$self->redirect_to('/');
	});

	$r->post('/register')->to('account#register');
	
	$r->get('/login')->to('auth#login', user_id => '');

	$r->post('/login' => sub {
		my $self = shift;
		
		my $address = $self->tx->remote_address;

		my $email 	= $self->param('email') || '';
		my $pass	= $self->param('pass') || '';
		my $res		= $users->find({ email => $email});
		my $count	= $res->count();
	
		unless( $count == 1) {
			$self->flash( error =>  "Error logging in" );
			$log->warn("Some how we got more than one user with email address $email");
			return $self->redirect_to('/login');
		}

		my $doc 	= $res->next;
		my $user_id 	= $doc->{'_id'}->to_string;
		my $username 	= $doc->{"username"};
		

		unless($self->bcrypt_validate($pass, $doc->{"pass"})) {
			$self->flash(error => "error logging in");
			$self->warn("failed attempt to login for $username from $address");
			return $self->redirect_to('/login');
		}

		$self->session( user_id 	=> $user_id );
		$self->session( username 	=> $username );
		$log->info("$username has logged in from $address");
		$self->redirect_to('/');
	} => 'auth/login');


	my $logged_in = $r->under( sub {
		my $self = shift;

		return 1 if $self->session('user_id');
		$self->redirect_to('/login');
		return undef;
	});

	$logged_in->get('/account')->to('account#account');


	$logged_in->get('/logout' => sub {
		my $self = shift;
		$self->session(expires => 1);
		$self->redirect_to('/');
	});
	
	$logged_in->get('/update_account')->to('account#update_account');
	
	$logged_in->post('/update')->to('account#update');

}

1;
