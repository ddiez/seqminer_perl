#!/usr/bin/env perl

use SeqMiner::SearchSet;
use Getopt::Long;

my %O = ();
GetOptions(\%O, 's', 'a', 'd', 't=s');

my $help =<<HELP;

Usage: vardb_analyze.pl {-a [-s -d] [t type]}

Options:

   -a   do sequences and domains
   -s   analyze sequences
   -d   analyze domains
   -t   target sequences (genome, isolate) [default: all]

HELP

die $help if scalar keys %O == 0;

my $all = 0;
$all = 1 if exists $O{a};

my $do_sequence = 0;
my $do_domain = 0;

$do_sequence = 1 if $O{s} or $all == 1;
$do_domain = 1 if $O{d} or $all == 1;

my $ss = new SeqMiner::SearchSet;
$ss->analyze_sequence({ type => $O{t} }) if $do_sequence;
$ss->analyze_domain({ type => $O{t} }) if $do_domain;