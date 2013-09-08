package WikiRace::Core;
use lib '..';
use Helper;
use Mojo::Base 'Mojolicious::Controller';
use Data::Dumper;
use Mojo::Log;
use Mojo::UserAgent;

my $ua = Mojo::UserAgent->new;


sub welcome {
	my $self = shift;
	$self->render();
}

sub start {
        my $self = shift;
	# on the start page set current count to 0 (due to replay);
	$self->session('count' => '0');
	$self->session('bread_crumb' => '');
	$self->session('HighScore' => '');
	my $start; 
	my $finish;
	if($self->param('Insane')) {
		my $pages = $wiki->api({
			action          => 'query',
			list            => 'random',
			rnnamespace     => '0',
			rnlimit         => '2' });
		$start       = $pages->{query}->{random}->[0]->{'title'};
		$finish      = $pages->{query}->{random}->[1]->{'title'};
		$log->info("We have a crazy one... went full sheldon");
		$self->session('Insane' => 1);
	} else {
		my $article_count = $articles->count();
		srand();
		my $rand1 = int(rand($article_count));
		my $rand2 = int(rand($article_count));
		$log->info("$rand1 : $rand2");
		my $start_doc = $articles->find()->limit('-1')->skip($rand1)->next();
		my $finish_doc = $articles->find()->limit('-1')->skip($rand2)->next();
		$start = $start_doc->{'Title'};
		$finish = $finish_doc->{'Title'};
	};
	# Search to see if the pair already exists
	my $search_query = $records->find({ "start" => "$start", "finish" => "$finish" });
	my $CAF;
	if(my $search_doc = $search_query->next) {
        	$CAF = $search_doc->{'_id'}->{'value'};
        	$self->session( CAF => $CAF );
		$records->update({ _id => MongoDB::OID->new(value=>$CAF)}, {'$inc' => { 'count' => 1}});
	} else {
		my $insert_hash = $records->insert({ "start" => "$start", "finish" => "$finish" });
		 $CAF = $insert_hash->{'value'};
		$records->update({ _id => MongoDB::OID->new(value=>$CAF) }, {'$inc' => { 'count' => 1}});
	}
	$self->session( CAF => $CAF );
        $self->session( start => $start );
        $self->session( finish => $finish );
        my $finish_title = $finish;
        $finish_title =~ s/\s/_/g;
	my $start_title = $start; 
	$start_title =~ s/\s/_/g;
	$self->session( finish_title => $finish_title);
        my $page = $ua->get("http://en.wikipedia.org/wiki/$finish_title")->res->dom;
        my $wiki_data = $page->at('div#content.mw-body');
        $self->render(wiki_data => $wiki_data, start => $start, finish => $finish, start_title => $start_title);


}


sub getPage {
	my $self = shift;
	my $count = $self->session('count');
	my $start = $self->session('start');
	my $finish = $self->session('finish');
	my $finish_title = $self->session('finish_title');
	my $page_title = $self->param('wikiPage');
	my $crumb = $self->session('bread_crumb');
	my $CAF = $self->session('CAF');
	$log->info("Start : $start - Fin : $finish_title - Current : $page_title");
	if($page_title eq $finish_title) {
		$crumb = $crumb . "->$page_title";
		my $cscore_query = $records->find({ _id => MongoDB::OID->new(value=>$CAF)}, { score => 1});
		my $current_score = $cscore_query->next->{'Score'} || "100000";
		$log->info("curret :$count High :$current_score");
		if($count < $current_score) { 
			$self->session('HighScore' => '1');
			$self->session('count' => $count);
			$log->info("Record set for: $start -> $finish | Total Hops: $count");
		} else {
			#no highscore for you
		}
                $self->render(count => $count, template => 'core/victory');
        } else {
		if($count % 5) {
			$self->flash('hint' => '1');
		}
		if($crumb) {
			$crumb = $crumb . "->$page_title";
			$crumb =~ s/_/ /g;
			$self->session('bread_crumb' => $crumb);
		} else {
			$self->session('bread_crumb' => $start);
		}
		$page_title =~ s/\ /_/g;
		$log->debug("Starting get");
		my $page = $ua->get("http://en.wikipedia.org/wiki/$page_title")->res->dom;
		my $wiki_data = $page->at('div#content.mw-body');
		$log->debug("Starting replace");
		$wiki_data =~ s/\/wiki\//\/getPage\//g;
		$wiki_data =~ s/Jump to:.*//g;
		$log->debug("out of replace");
		$count++;
		$self->session( count => $count);
		$self->render(wiki_data => $wiki_data, count => $count);
	}
}

sub getWLink {
	my $self = shift;
	my $count = $self->session('count');
	my $start = $self->session('start');
	my $finish = $self->session('finish');
	my $finish_title = $self->session('finish_title');
	my $page_title = $self->param('wikiPage');
	$log->info("wlink Start : $start - Fin : $finish_title - Current : $page_title");
	$page_title =~ s/\ /_/g;
	my $page = $ua->get("http://en.wikipedia.org/w/index.php?title=$page_title")->res->dom;
	my $wiki_data = $page->at('div#content.mw-body');
	$wiki_data =~ s/\/wiki\//\/getPage\//g;
	$wiki_data =~ s/Jump to:.*//g;
	$self->session( count => $count);
	$self->render(template => 'core/getPage', wiki_data => $wiki_data, count => $count);
}





sub startChallenge {
	my $start; 
	my $finish;
        my $self = shift;
	# on the start page set current count to 0 (due to replay);
	$self->session('count' => '0');
	$self->session('bread_crumb' => '');
	if($self->param('caf_id')) {
		my $caf_id = $self->param('caf_id');
		my $record_data = $records->find({ _id => MongoDB::OID->new(value=>$caf_id)}, { start => 1, finish => 1});
		my $doc = $record_data->next;
		$start = $doc->{"start"};
		$finish = $doc->{"finish"};

	} else {
		$start = $self->param('start');
		$finish = $self->param('finish');

	};
	$log->info("start : $start - finish : $finish");
        $self->session( start => $start );
        $self->session( finish => $finish );
        my $finish_title = $finish;
        $finish_title =~ s/\s/_/g;
	my $start_title = $start; 
	$start_title =~ s/\s/_/g;
	$self->session( finish_title => $finish_title);
        my $page = $ua->get("http://en.wikipedia.org/wiki/$finish_title")->res->dom;
        my $wiki_data = $page->at('div#content.mw-body');
	$records->update({ "start" => "$start", "finish" => "$finish" },{'$inc' => { 'count' => 1}}, {"upsert" => 1});
	my $id = $records->find({ "start" => "$start", "finish" => "$finish" });
	my $CAF;
	if(my $id_doc = $id->next) {
        	$CAF = $id_doc->{'_id'}->{'value'};
        	$self->session( CAF => $CAF );
		$records->update({ _id => MongoDB::OID->new(value=>$CAF)}, {'$inc' => { 'count' => 1}});
	} else {
		my $insert_return = $records->insert({ "start" => "$start", "finish" => "$finish" });
		$CAF = $insert_return->{'value'};
        	$self->session( CAF => $CAF );
	}
        $self->render(wiki_data => $wiki_data, start => $start, finish => $finish, start_title => $start_title);
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
	if($self->session('HighScore')) {
		my %h = ();
		my $highscore_hash = {
				'User' 		=> $user, 
				'Start' 	=> $start, 
				'Finish' 	=> $finish,
				'Count' 	=> $count, 
				'Path'		=> $crumbs
		};
		$records->update({ _id => MongoDB::OID->new(value=>$CAF)}, {'$push' => { 'HighScore' => $highscore_hash }});
		$records->update({ _id => MongoDB::OID->new(value=>$CAF)}, {'$set' => {'Score' => $count}});
		$users->update({ username => "$user" }, {'$push' => { 'Records_Set' => $highscore_hash }});
		delete $self->session->{'HighScore'};
		$self->render( user => $user, start => $start, finish => $finish, count => $count ); 
	} else {
		$self->redirect_to("/");
	}




}

1;
