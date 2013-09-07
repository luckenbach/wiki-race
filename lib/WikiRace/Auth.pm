package WikiRace::Auth;
use lib '..';
use Helper;
use Mojo::Base 'Mojolicious::Controller';

sub login {
	my $self = shift;
	if($self->session('user_id')) {
		return $self->redirect_to('/');
	} else {
		return $self->render( template => 'auth/login');
	}
	$self->render();

}

1;
