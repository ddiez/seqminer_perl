#!/usr/bin/env perl

use varDB::SearchSet;
#use varDB::ScanSet;
use Getopt::Long;

my %O = ();
GetOptions(\%O, 's', 'a', 't=s');


my $all = 1;
$all = 0 if scalar keys %O > 0;

# search sequences by taxon.
my $ss = new varDB::SearchSet;

$ss->search({ type => $O{'t'} }) if $all or $O{s};
$ss->analyze if $all or $O{a};

# scan sequences linked to papers.
#my $ss2 = new varDB::ScanSet;
#$ss2->scan;

# do something...