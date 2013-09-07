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

sub records {
	my $self = shift;
	$self->render();
}
1;
