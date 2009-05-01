#!/usr/bin/env perl

use strict;
use warnings;

use SeqMiner::Config;
use SeqMiner::SearchSet;
my $ss = new SeqMiner::SearchSet;
for my $search ($ss->item_list) {
	$search->taxon->debug;
	$search->commit;
}