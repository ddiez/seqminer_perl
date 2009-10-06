#!/usr/bin/env perl
#
#  This is the main script for updating models used for mining gene families.
#  There are two types of models, those used with HMMMER, i.e. HMM models
#  that can be for fragments or for full models, and those used with PSI-Blast
#  that includes the output of iterative blast (pgp file), the seed file and
#  the check file. Only the last two are actually needed for running a new
#  search.
#
#
use SeqMiner::OrthologSet;
use Getopt::Long;

my %O = ();
GetOptions(\%O, 's', 'h', 'a');

my $help = <<"HELP";

#!! WARNING !!
#  This is the main script for updating models used for mining gene families.
#  There are two types of models, those used with HMMMER, i.e. HMM models
#  that can be for fragments or for full models, and those used with PSI-Blast
#  that includes the output of iterative blast (PGP file), the SEED file and
#  the CHECK file. Only the last two are actually needed for running a new
#  search.
#!! WARNING !!

Usage:

 vardb_update_models.pl {-s -h -a}

Options:

   -h   update HMM models
   -s   update PSI-Blast models
   -a   update both HMM and PSI-Blast models
 
HELP

die $help if scalar keys %O == 0;

my $all = 0;
$all = 1 if exists $O{a};

# update models by taxon.
my $os = new SeqMiner::OrthologSet;
(($all == 1) | $O{s}) && do {	
	$os->update_seed;
};

(($all == 1) | $O{h}) && do {
	$os->update_hmm;
};

