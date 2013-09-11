package WikiRace::Highscore;
use lib '..';
use Helper;
use Mojo::Base 'Mojolicious::Controller';
use Data::Dumper;
use Mojo::Log;





sub scoreForm {
	my $self = shift;
	$self->render( template => 'highscore/high-score-modal' );


}

sub setHighScore {
        my $self = shift;
        my $user = $self->param('User')|| "Anon";
        my $start = $self->session('start');
        my $finish = $self->session('finish');
        my $crumbs = $self->session('bread_crumb');
        my $count = $self->session('count');
        my $auth = $self->session('HighScore');
        my $CAF = $self->session('CAF');
        my $Sheldon = $self->session('Insane') || "0";
	if(($user =~ m/<.+?>/) || ($user =~ m/%.?+/)) {
		return $self->render( template => 'highscore/responce-modal', responce => '<div class="alert alert-danger"><strong>Unable to submit your highscore, please try to not use < > or html code in your name</strong></div>');
	}
        if($self->session('HighScore')) {
                my %h = ();
                my $highscore_hash = {
                                'User'          => $user,
                                'Start'         => $start,
                                'Finish'        => $finish,
                                'Count'         => $count,
                                'Path'          => $crumbs
                };
                $records->update({ _id => MongoDB::OID->new(value=>$CAF)}, {'$push' => { 'HighScore' => $highscore_hash }});
                $records->update({ _id => MongoDB::OID->new(value=>$CAF)}, {'$set' => {'Score' => $count}});
                $users->update({ username => "$user" }, {'$push' => { 'Records_Set' => $highscore_hash }});
                delete $self->session->{'HighScore'};
		return $self->render( template => 'highscore/responce-modal', responce => '<div class="alert alert-success"><strong>Highscore has been updated!</strong></div>');
        } else {
                $self->redirect_to("/");
        }




}





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
	my $doc = $query->next;
	my $array_ref = $doc->{'Records_Set'};
        $self->render(json => { sEcho => $sEcho, aaData => [@$array_ref]});
}


sub records {
	my $self = shift;
	$self->render();
}
1;
