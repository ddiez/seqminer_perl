#!/usr/bin/env perl


use SeqMiner::TaxonSet;

my $ts = new SeqMiner::TaxonSet;
my $n = 0;
for my $taxon ($ts->item_list) {
	printf "%i\t%s\t%s\n", $n++, $taxon->name, $taxon->type;
}
print "----------------------------\n";
print "Select species to search [All]: ";
my $spe = <STDIN>;
chop $spe;
$spe = "All" if $spe eq "";
print "Selected [$spe]\n";