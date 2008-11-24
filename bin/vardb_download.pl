#!/usr/bin/env perl
use varDB::TaxonSet;

my $ts = new varDB::TaxonSet;

foreach my $taxon ($ts->item_list) {
	$taxon->debug;
	#$taxon->type eq "isolate" && do
	#{
	#	$taxon->download("nuccore");
	#	$taxon->download("nucest");
	#};
	
	$taxon->type eq "genome" && do
	{
		$taxon->download;
	};
}