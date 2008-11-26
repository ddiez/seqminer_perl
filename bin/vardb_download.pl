#!/usr/bin/env perl
use varDB::TaxonSet;
use Getopt::Long;

my %O = ();
GetOptions(\%O, 'g', 'i', 'db=s');


my $all = 1;
$all = 0 if scalar keys %O > 0;

my $ts = new varDB::TaxonSet;
foreach my $taxon ($ts->item_list) {
	($taxon->type eq "isolate" & ($all == 1 | $O{i})) && do
	{
		$taxon->debug;
		print "iso\n";
		if ($O{db} eq "nuccore") {
			$taxon->download("nuccore");	
		} elsif ($O{db} eq "nucest") {
			$taxon->download("nucest");
		} else {
			$taxon->download("nuccore");
			$taxon->download("nucest");
		}
		
	};
	
	($taxon->type eq "genome" & ($all == 1 | $O{g})) && do
	{
		$taxon->debug;
		$taxon->download;
	};
}