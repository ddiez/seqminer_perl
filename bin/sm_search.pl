#!/usr/bin/env perl

use SeqMiner::SearchSet;
use Getopt::Long;

my %O = ();
GetOptions(\%O, 's', 'a', 'd', 't=s');

my $help =<<HELP;

Usage: sm_search.pl {-a [-s -p] [t type]}

Options:

   -a   search sequences and domains
   -s   search sequences
   -d   search domains
   -t   target sequences (genome, isolate, all) [default: all]

HELP

die $help if scalar keys %O == 0;

my $all = 0;
$all = 1 if exists $O{a};

my $do_sequence = 0;
my $do_domain = 0;

$do_sequence = 1 if $O{s} or $all == 1;
$do_domain = 1 if $O{d} or $all == 1;

my $ss = new SeqMiner::SearchSet;
$ss->search_sequence({ type => $O{t} }) if $do_sequence;
$ss->search_domain({ type => $O{t} }) if $do_domain;