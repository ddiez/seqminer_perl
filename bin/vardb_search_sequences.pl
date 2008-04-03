#!/usr/bin/env perl

use strict;
use warnings;

use varDB::Config;
use varDB::SearchResult;
use varDB::SearchParam;

my $param = new varDB::SearchParam({file => shift});
$param->debug;
$param->create_dir_structure;

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
	## 1. do hmmer and find the best seed possible.

	# retrieve model with hmmfetch library hmm_name.
	# use libraries Pfam_ls and Pfam_fs.
	my $fs = $hmm_name."_fs";
	my $ls = $hmm_name."_ls";
	print STDERR "* fetching Pfam models ... ";
	system "hmmfetch $HMMDB/$PFAM_VERSION/Pfam_ls $hmm_name > $ls.hmm";
	system "hmmfetch $HMMDB/$PFAM_VERSION/Pfam_fs $hmm_name > $fs.hmm";
	print STDERR "OK\n";

	# search in protein genome.
	print STDERR "* searching protein database (hmmer) ... ";
	system "hmmsearch $ls.hmm $GENOMEDB/$organism_dir/protein.fa > $base-protein\_ls.log";
	system "hmmsearch $fs.hmm $GENOMEDB/$organism_dir/protein.fa > $base-protein\_fs.log";
	print STDERR "OK\n";
	
	# TODO:
	# check for genes with multiple matches (with different offset/revcom) and
	# create an unified list for sequence retrieval? 
	#
	# 1.4 do genewisedb for search with hmm in nucleotide database.
	print STDERR "* searching nucleotide database (genewisedb) ... ";
	system "genewisedb -quiet -hmmer $ls.hmm $GENOMEDB/$organism_dir/gene.fa > $base-gene\_ls-genewise.log";
	system "genewisedb -quiet -hmmer $fs.hmm $GENOMEDB/$organism_dir/gene.fa > $base-gene\_fs-genewise.log";
	print STDERR "OK\n";
	
	###########################################################
	## 2. do psi-blast find best protein hits and get pssm.
	# get seed from hmmer search.
	
	# the best seed would be the best hit in the Pfam_ls search.
	# TODO: check that it is indeed a suitable seed (e-value/score).
	# if no suitable seed found, use the one provided in the config file.
	my $list = new varDB::SearchResult({file => "$base-protein\_ls.log", method => 'hmmer'});
	my $seed = $list->best_hit;
	
	my $seedfile = "$family-$organism_dir.seed";
	system "extract_fasta.pl -d $seed -i $GENOMEDB/$organism_dir/protein.idx > $seedfile";
	
	# search in protein database with psi-blast and generate pssm file.
	print STDERR "* searching protein database (psi-blast) ... ";
	system "blastpgp -d $GENOMEDB/$organism_dir/protein -i $seedfile -s T -j $iter -h $pssm_eval -C $base.chk -F T -b 10000  > $base.blastpgp";
	print STDERR "OK\n";
	# write psi-blast report.
	system "psiblast_report.pl -i $base.blastpgp -e $pssm_eval > $base-cycles.txt";

	#####################################################
	## 3. do psitblastn and find best nuclotide hits.
	# search in nucleotide database with psitblastn.
	print STDERR "* searching nucleotide database (psitblastn) ... ";
	system "blastall -p psitblastn -d $GENOMEDB/$organism_dir/gene -i $seedfile -R $base.chk -b 10000 > $base.psitblastn";
	print STDERR "OK\n";
}
