#!/usr/bin/env perl

use SeqMiner::SearchSet;
use SeqMiner::SearchSet::Search;
use SeqMiner::OrthologSet;
use SeqMiner::TaxonSet;
use Getopt::Long;

my %O = ();
GetOptions(\%O, 't=s', 'o=s');

my $help =<<HELP;

Usage: sm_megasearch.pl

Options:

HELP

#die $help if scalar keys %O == 0;

my $tf = [$O{t}];
my $of = [$O{o}];

my $ss = new SeqMiner::SearchSet({empty => 1});
my $os = new SeqMiner::OrthologSet;
$os = $os->filter_by_ortholog_name($of);
my $ts = new SeqMiner::TaxonSet;
$ts = $ts->filter_by_taxon_name($tf);

for my $taxon ($ts->item_list) {
	if ($taxon->type eq "spp") {
		for my $family ($os->item_list) {
			print STDERR $taxon->name, "\t", $family->hmm, "\n";
			my $search = new SeqMiner::SearchSet::Search;
			$search->id($taxon->type.".".$taxon->id.".".$family->id.".".$taxon->family);
			$search->search($taxon);
			$search->family($family);
			#$search->type($taxon->type);
			$search->type("genome");
			$ss->add($search);
		}
	}
}

#$ss->search_domain({type => "genome"});
