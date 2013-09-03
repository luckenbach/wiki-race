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
        my $pages = $wiki->api({
                action          => 'query',
                list            => 'random',
                rnnamespace     => '0',
                rnlimit         => '2' });
        my $start       = $pages->{query}->{random}->[0]->{'title'};
        my $finish      = $pages->{query}->{random}->[1]->{'title'};
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
                $self->render(count => $count, template => 'core/victory');
        } else {
		if($crumb) {
			$crumb = $crumb . "->$page_title";
			$crumb =~ s/_/ /g;
			$self->session('bread_crumb' => $crumb);
		} else {
			$self->session('bread_crumb' => $start);
		}
		$log->debug("Starting get");
		my $page = $ua->get("http://en.wikipedia.org/wiki/$page_title")->res->dom;
		$log->debug("Starting Parse");
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

1;
