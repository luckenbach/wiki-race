package WikiRace::Core;
use lib '..';
use Helper;
use Mojo::Base 'Mojolicious::Controller';
use Data::Dumper;
use Mojo::UserAgent;
my $ua = Mojo::UserAgent->new;




sub welcome {
	my $self = shift;
	$self->render();
}

sub start {
        my $self = shift;
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
        my $page = $ua->get("http://en.wikipedia.org/wiki/$finish_title");
        my $wiki_data = $page->res->dom->at('div#content.mw-body')->all_text;
	
        $self->render(wiki_data => $wiki_data, start => $start, finish => $finish);


}


sub getPage {
	my $self = shift;
	my $count = $self->session('count') ||"0";
	my $start = $self->session('start');
	my $finish = $self->session('finish');
	my $page_title = $self->param('wikiPage');
	if($page_title =~ /$finish/) {
                $self->render(count => $count, template => 'core/victory');
        } else {
		my $page = $ua->get("http://en.wikipedia.org/wiki/$page_title")->res->dom;
		print Dumper($page);
		my $wiki_data = $page->at('div#content.mw-body');
		$wiki_data =~ s/\/wiki\//\/getPage\//g;
		$wiki_data =~ s/Jump to:.*//g;
		$wiki_data =~ s/.*\/w\/.*//g;
		$count++;
		$self->session( count => $count);
		$self->render(wiki_data => $wiki_data, count => $count);
	}
}

1;
