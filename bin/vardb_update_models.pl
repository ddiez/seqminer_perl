#!/usr/bin/env perl

use SeqMiner::SearchSet;
use SeqMiner::OrthologSet;
use Getopt::Long;

my %O = ();
GetOptions(\%O, 's', 'h');


my $all = 1;
$all = 0 if scalar keys %O > 0;

# update models by taxon.
my $ss = new SeqMiner::SearchSet;
($all == 1 | $O{s}) && do {	
	$ss->seed;
};

($all == 1 | $O{h}) && do {
	$ss->hmm;
};
