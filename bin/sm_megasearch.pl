#!/usr/bin/env perl

use SeqMiner::SearchSet;
use SeqMiner::SearchSet::Search;
use SeqMiner::OrthologSet;
use SeqMiner::TaxonSet;
use Getopt::Long;

#my %O = ();
#GetOptions(\%O, 't=s', 'o=s');

my @of;
my @tf; 
my %O;
GetOptions('-h' => \%O, 'tf=s' => \@tf, 'of=s' => \@of);

my $help =<<HELP;

Usage: sm_megasearch.pl

Options:

   -h
   -tf
   -of

HELP

die $help if exists $O{h};

my $ss = new SeqMiner::SearchSet({empty => 1});
my $os = new SeqMiner::OrthologSet;
$os = $os->filter_by_ortholog_name(\@of);
my $ts = new SeqMiner::TaxonSet;
$ts = $ts->filter_by_taxon_name(\@tf);

$ss->add({taxon => $ts, ortholog => $os});
$ss->debug;
$ss->search({source => "genome", type => "domain"});
