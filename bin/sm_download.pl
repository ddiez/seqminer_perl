#!/usr/bin/env perl
use SeqMiner::TaxonSet;
use Getopt::Long;

my %O = ();
GetOptions(\%O, 'g', 'i', 'db=s', 'd', 'f');


my $all = 1;
$all = 0 if scalar keys %O > 0;

my $ts = new SeqMiner::TaxonSet;
foreach my $taxon ($ts->item_list) {
	$taxon->type eq "isolate" && do
	{
		$taxon->debug if $all == 1 or $O{d} or $O{f};
		if ($O{db} eq "nuccore") {
			$taxon->download("nuccore") if $all == 1 or $O{d};
			$taxon->filter("nuccore") if $all == 1 or $O{f};	
		} elsif ($O{db} eq "nucest") {
			$taxon->download("nucest") if $all == 1 or $O{d};
			$taxon->filter("nucest") if $all == 1 or $O{f};
		} else {
			$taxon->download("nuccore") if $all == 1 or $O{d};
			$taxon->filter("nuccore") if $all == 1 or $O{f};
			$taxon->download("nucest") if $all == 1 or $O{d};
			$taxon->filter("nucest") if $all == 1 or $O{f};
		}
		
	};
	
	($taxon->type eq "genome" & ($all == 1 | $O{g})) && do
	{
		$taxon->debug;
		$taxon->download;
	};
}