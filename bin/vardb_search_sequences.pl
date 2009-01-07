#!/usr/bin/env perl
#
# STATUS: stable
#
#  This is the main script for searching sequences based on profile alignment.
#  * HMM are used for domain-based profile similariry search:
#    - HMMER for searching protein databases.
#    - Wise for searching nucleotide databases.
#  * PSSM are used for full sequence-based profile similarity search:
#    - PSI-Blast for searching protein databases.
#    - Blast for seaching nucleotide databases.
#  * The seed for the PSSM is obtained from the HMM search. If no hits can be
#    found, then the PSSM search is skipped.

use strict;
use warnings;

use SeqMiner::Config;
use SeqMiner::Config::Param;
use SeqMiner::ResultSet;
use Getopt::Long;

my $param = new SeqMiner::Config::Param;
$param->debug;

my %O = ();
GetOptions(\%O, 'c');

my $help = <<"HELP";

#!! WARNING !!
#  This is the main script for searching sequences based on profile alignment.
#  * HMM are used for domain-based profile similariry search:
#    - HMMER for searching protein databases.
#    - Wise for searching nucleotide databases.
#  * PSSM are used for full sequence-based profile similarity search:
#    - PSI-Blast for searching protein databases.
#    - Blast for seaching nucleotide databases.
#  * The seed for the PSSM is obtained from the HMM search. If no hits can be
#    found, then the PSSM search is skipped.
#!! WARNING !!

	vardb_search_sequences.pl [-c]
	
	-c   creates 'de novo' the directory structure.

HELP

$param->create_dir_structure if exists $O{c};

while (my $info = $param->next_param) {
	$info->debug;
	$param->chdir($info, 'search');
	
	my $family = $info->family;
	my $organism_dir = $info->organism_dir;
	my $base = "$family-$organism_dir";
	my $hmm_name = $info->hmm_name;
	my $iter = $info->iter;
	my $pssm_eval = $info->pssm_eval;
	
	$base = $info->base;
	###################################################
	## 1. do hmm based search.

	# retrieve model with hmmfetch library hmm_name.
	# use libraries Pfam_ls and Pfam_fs.
	my $fs = $hmm_name."_fs";
	my $ls = $hmm_name."_ls";
	print STDERR "* fetching Pfam models ... ";
	system "hmmfetch $HMMDB/$PFAM_VERSION/Pfam_ls $hmm_name > $ls.hmm";
	system "hmmfetch $HMMDB/$PFAM_VERSION/Pfam_fs $hmm_name > $fs.hmm";
	print STDERR "OK\n";

	# search in protein sequences.
	print STDERR "* searching protein database (hmmer) ... ";
	system "hmmsearch $HMMERPARAM $ls.hmm $GENOMEDB/$organism_dir/protein.fa > $base-protein\_ls.log";
	system "hmmsearch $HMMERPARAM $fs.hmm $GENOMEDB/$organism_dir/protein.fa > $base-protein\_fs.log";
	print STDERR "OK\n";
	
	# search in nucleotide sequences.
	#
	# From the Wise2 documentation.
	# Scores
	#
	# The scoring system for the algorithms, as eluded to earlier is a 
	# Bayesian score. This score is related to the probability that model 
	# provided in the algorithm exists in the sequence (often called the 
	# posterior). Rather than expressing this probability directly I report 
	# a log-odds ratio of the likelihood of the model compared to a random model 
	# of DNA sequence. This ratio (often called bits score because the log is 
	# base 2) should be such that a score of 0 means that the two 
	# alternatives it has this homology and it is a random DNA sequence are 
	# equally likely. However there are two features of the scoring scheme that 
	# are not worked into the score that means that some extra calculations are 
	# required
	# The score is reported as a likelihood of the models, and to convert this 
	# to a posterior probability you need to factor in the ratio of the prior 
	# probabilities for a match. Because you expect a far greater number of 
	# sequences to be random than not, this probability of your prior knowledge 
	# needs to be worked in. Offhand sensible priors would in the order of 
	# probability that there is a match being roughly proportional to the 
	# database size.
	# The posterior probability should not merely be in favour of the homology 
	# model over the random model but also be confident in it. In other words you 
	# would want probabilities in the 0.95 or 0.99 range before being confident 
	# that this match was correct.
	# These two features mean that the reported bits score needs to be above 
	# some threshold which combines the effect of the prior probabilities and the 
	# need to have confidence in the posterior probability. In this field people 
	# do not tend to work the threshold out rigorously using the above technique, 
	# as in fact, deficiencies in the model mean that you end up choosing some 
	# arbitary number for a cutoff. In my experience, the following things hold 
	# true: bit scores above 35 nearly always mean that there is something there, 
	# bit scores between 25-35 generally are true, and bit scores between 18-25 
	# in some families are true but in other families definitely noise. I don't 
	# trust anything with a bit score less than 15 bits for these DNA based 
	# searches. For protein-HMM to protein there are a number of cases where very 
	# negative bit scores are still 'real' (this is best shown by a classical 
	# statistical method, usually given as e-values, which is available from the 
	# HMMer2 package), but this doesn't seem to occur in the DNA searches.
	# I have been thinking about using a classical statistic method on top of 
	# the bit score, assuming the distribution is an extreme value distribution 
	# (EVD), but for DNA it becomes difficult to know what to do with the problem 
	# of different lengths of DNA. As these can be wildly different, it is hard 
	# to know precisely how to handle it. Currently a single HMM compared to a 
	# DNA database can produce e-values using Sean Eddy's EVD fitting code but, I 
	# am not completely confident that I am doing the correct thing. Please use 
	# it, but keep in mind that it is an experimental feature.
	#
	print STDERR "* searching nucleotide database (genewisedb) ... ";
	system "genewisedb $WISEPARAM -hmmer $ls.hmm $GENOMEDB/$organism_dir/gene.fa > $base-gene\_ls.log";
	system "genewisedb $WISEPARAM -hmmer $fs.hmm $GENOMEDB/$organism_dir/gene.fa > $base-gene\_fs.log";
	print STDERR "OK\n";
	
	###########################################################
	## 2. do psi-blast find best protein hits and get pssm.
	
	# the seed would be the best hit in the Pfam_ls search, but if
	# there is nothing there, then the next one will be tested.
	# TODO: check that it is indeed a suitable seed (e-value/score).
	# if no suitable seed found, use the one provided in the config file.
	my @search_type = ("protein\_ls", "protein\_fs", "gene\_ls", "gene\_fs");
	my $bh = undef;
	foreach my $search_type (@search_type) {
		my $rs = new SeqMiner::ResultSet({file => "$base-$search_type.log"});
		$bh = $rs->get_result_by_pos(0)->best_hit;
		last if defined $bh
	}

	if (defined $bh) {
		my $seed = $bh->id;
	
		my $seedfile = "$family-$organism_dir.seed";
		#system "extract_fasta.pl -d $seed -i $GENOMEDB/$organism_dir/protein.idx > $seedfile";
		system "fastacmd -d $GENOMEDB/$organism_dir/protein -s $seed > $seedfile";
		
		# search in protein database with psi-blast and generate pssm file.
		print STDERR "* searching protein database (psi-blast) ... ";
		system "blastpgp -d $GENOMEDB/$organism_dir/protein -i $seedfile -s T -j $iter -h $pssm_eval -C $base.chk -F T -b 10000  > $base.blastpgp";
		print STDERR "OK\n";
		# write psi-blast report.
		system "psiblast_report.pl -i $base.blastpgp -e $pssm_eval > $base-cycles.txt";
	
		# search in nucleotide database with psitblastn.
		print STDERR "* searching nucleotide database (psitblastn) ... ";
		system "blastall -p psitblastn -d $GENOMEDB/$organism_dir/gene -i $seedfile -R $base.chk -b 10000 > $base.psitblastn";
		print STDERR "OK\n";
	} else {
		print STDERR "* no best hit found - skipping psi-blast search.\n";
	}
}
