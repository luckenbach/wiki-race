package Helper;


use strict;
use Exporter;

use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
use Data::Dumper;
use LWP::UserAgent;
use IO::Socket::SSL qw();
use MIME::Base64;
use Mojo::Log;
use MediaWiki::API;


$VERSION = 1.00;
@ISA    = qw(Exporter);
@EXPORT = qw(
	$wiki
	$log

);
@EXPORT_OK = qw(
	$wiki
	$log
);

############################ User Variables ###############################







############################################################################

# Setup logging

our $path = 'log/wiki_race.log';
our $log = Mojo::Log->new(path => $path, level => 'info');


# Wikipedia API connection

our $wiki = MediaWiki::API->new();
$wiki->{config}->{api_url} = 'http://en.wikipedia.org/w/api.php';


# Wikipeida parser
