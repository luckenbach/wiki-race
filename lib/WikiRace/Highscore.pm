package WikiRace::Highscore;
use lib '..';
use Helper;
use Mojo::Base 'Mojolicious::Controller';
use Data::Dumper;
use Mojo::Log;


sub getHighScore {
        my $self = shift;
        my $sEcho = $self->param('_') || "42";
        my $query = $records->find({ HighScore => {'$exists' =>1 }});
        my $h;
        my @HS_Data;
        while($h = $query->next) {
               	my $hs = $h->{HighScore};
		my $hash = shift @$hs;
		push(@HS_Data, $hash);
        }
        $self->render(json => { sEcho => $sEcho, aaData => [@HS_Data]});
}


sub personalHighScore {
        my $self = shift;
        my $sEcho = $self->param('_') || "42";
	my $user_id = $self->param('user_id');
        my $query = $users->find({ Records_Set => {'$exists' =>1 }, username => $self->session('username')});
        my $ph;
        my @pHS_Data;
        while($ph = $query->next) {
                my $phs = $ph->{Records_Set};
                my $phash = shift @$phs;
		delete $phash->{'User'};
                push(@pHS_Data, $phash);
        }
        $self->render(json => { sEcho => $sEcho, aaData => [@pHS_Data]});
}


sub records {
	my $self = shift;
	$self->render();
}
1;
