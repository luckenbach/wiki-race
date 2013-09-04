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
use MongoDB;
use MongoDB::OID;


$VERSION = 1.00;
@ISA    = qw(Exporter);
@EXPORT = qw(
	$wiki
	$log
	$client 
	$db 
	$articles
	$records 
	$users 
);
@EXPORT_OK = qw(
	$wiki
	$log
	$client 
	$db 
	$articles
	$records 
	$users 

);

############################ User Variables ###############################







############################################################################

# Setup logging

our $path = 'log/wiki_race.log';
our $log = Mojo::Log->new(path => $path, level => 'info');


# Wikipedia API connection

our $wiki = MediaWiki::API->new();
$wiki->{config}->{api_url} = 'http://en.wikipedia.org/w/api.php';

# Mongo Connection
our $client = MongoDB::MongoClient->new or warn "Unable to connect";
our $db = $client->get_database('WikiRace');
our $articles = $db->get_collection('Articles');
our $records = $db->get_collection('Records');
our $users = $db->get_collection('users');
