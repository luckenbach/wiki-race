#!/usr/bin/perl

use strict;
use warnings;


use lib '../lib';
use Helper;
use File::Slurp;

use Data::Dumper;

my $query = $records->find({ HighScore => {'$exists' =>1 }});

my $h; 
my @HS_Data;
while($h = $query->next) {
	my $hs = $h->{HighScore};
	my $hash = shift @$hs;
	push(@HS_Data, $hash);
}
print Dumper(@HS_Data);
