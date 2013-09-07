#!/usr/bin/perl

use strict;
use warnings;


use lib '../lib';
use Helper;
use File::Slurp;
use Data::Dumper;


my $article_count = $articles->count();
my $rand1 = int(rand($article_count));
my $rand2 = int(rand($article_count));
my $start_doc = $articles->find()->limit('-1')->skip($rand1)->next();
my $finish_doc = $articles->find()->limit('-1')->skip($rand2)->next();
my $start = $start_doc->{'Title'};
my $finish = $finish_doc->{'Title'};

print "$start : $finish\n";
