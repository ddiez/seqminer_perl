#!/usr/bin/env perl

use varDB::SearchSet;
#use varDB::ScanSet;

# search sequences by taxon.
my $ss = new varDB::SearchSet;
$ss->search;	# search.
$ss->analyze;	# analyze search results.

# scan sequences linked to papers.
#my $ss2 = new varDB::ScanSet;
#$ss2->scan;

# do something...