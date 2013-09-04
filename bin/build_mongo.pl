#!/usr/bin/perl

use strict;
use warnings;


use lib '../lib';
use Helper;
use File::Slurp;

use Data::Dumper;
my @lines_ref = read_file('./list.txt');
chomp(@lines_ref);
my @update;
foreach my $title (@lines_ref) {
	my $title_hash = {
		Title => $title
	};
	push(@update, $title_hash);
}

$articles->batch_insert([@update],{"upsert" =>1});
