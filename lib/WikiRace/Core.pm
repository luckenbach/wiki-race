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
	} else {
		my $article_count = $articles->count();
		my $rand1 = int(rand($article_count));
		my $rand2 = int(rand($article_count));
		my $start_doc = $articles->find()->limit('-1')->skip($rand1)->next();
		my $finish_doc = $articles->find()->limit('-1')->skip($rand2)->next();
		$start = $start_doc->{'Title'};
		$finish = $finish_doc->{'Title'};
	};
	my $insert_hash = $records->insert({ "start" => "$start", "finish" => "$finish" });
	$records->update({ "start" => "$start", "finish" => "$finish" }, {'$inc' => { 'count' => 1}});
	my $CAF = $insert_hash->{'value'};
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
	$log->info("Start : $start - Fin : $finish_title - Current : $page_title");
	if($page_title eq $finish_title) {
		my $current_score = $records->find({ "start" => "$start", "finish" => "$finish" }, { score => 1});
		if($count < $current_score) { 
			$self->session('HighScore' => '1');
			$self->session('count' => $count);
			$log->info("Record set for: $start -> $finish | Total Hops: $count");
		} else {
			#no highscore for you
		}
                $self->render(count => $count, template => 'core/victory');
        } else {
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
	$log->info("Start : $start - Fin : $finish_title - Current : $page_title");
	$page_title =~ s/\ /_/g;
	my $page = $ua->get("http://en.wikipedia.org/w/index.php?title=$page_title")->res->dom;
	my $wiki_data = $page->at('div#content.mw-body');
	$wiki_data =~ s/\/wiki\//\/getPage\//g;
	$wiki_data =~ s/Jump to:.*//g;
	$count++;
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
	$records->insert({ "start" => "$start", "finish" => "$finish" });
        my $insert_hash = $records->insert({ "start" => "$start", "finish" => "$finish" });
        $records->update({ "start" => "$start", "finish" => "$finish" }, {'$inc' => { 'count' => 1}});
        my $CAF = $insert_hash->{'value'};
        $self->session( CAF => $CAF );
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
	if($self->session('HighScore')) {
		my $score_string = "$user:$count:$crumbs";
		$records->update({ "start" => "$start", "finish" => "$finish" }, {'$push' => { 'HighScore' => $score_string}});

		$self->render( user => $user, start => $start, finish => $finish, count => $count ); 
	} else {
		$self->render(text => "You shouldnt be here");
		$log->info("Setting score");
	}




}

1;
