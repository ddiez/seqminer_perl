#!/usr/bin/env perl

use strict;
use warnings;

use varDB::Config;
#use varDB::Position;
#use varDB::ListIO;
use varDB::SearchResult;
#use varDB::SearchIO;
use varDB::SearchParam;
#use Sets;

#my $file = shift;
#$file = $VARDB_SEARCH_FILE if !defined $file;

#print STDERR "* config file: $file\n";

# define locations.
#my $VARDB_RELEASE = 1;
#my $OUTDIR = "$VARDB_HOME/families/vardb-$VARDB_RELEASE";
#if ($DEBUG == 1) {
#	my $randir = &get_random_dir;
#	$OUTDIR = "$VARDB_HOME/families/test/$randir";
#}
#print STDERR "* output_dir: $OUTDIR\n";

# create working directory, die on failure.
#if (! -d $OUTDIR) {
#	mkdir $OUTDIR;
#	mkdir "$OUTDIR/search";
#	mkdir "$OUTDIR/analysis";
#} else {
#	die "directory $OUTDIR already exists!.\n";
#}

#if ($DEBUG == 1) {
#	unlink "$VARDB_HOME/families/test/last";
#	system "ln -s $OUTDIR $VARDB_HOME/families/test/last";
#}

#open IN, "$file" or die "$!";
#while (<IN>) {
#	next if /^[#|\n]/;
#	chomp;
	
#	my $info = new varDB::SearchIO($_);
my $param = new varDB::SearchParam({file => shift});
$param->debug;
$param->create_dir_structure;

while (my $info = $param->next_param) {
	$info->debug;
	$param->chdir($info, 'search');
	
	my $family = $info->family;
	my $organism_dir = $info->organism_dir;
	#my $eexons = $info->eexons;
	my $base = "$family-$organism_dir";
	my $hmm_name = $info->hmm_name;
	my $iter = $info->iter;
	my $pssm_eval = $info->pssm_eval;
	
	#my ($organism, $strain, $organism_dir, $super, $family, $seed, $pssm_eval, $psi_eval, $tbn_eval, $iter, $hmm_acc, $hmm_name, $hmm_eval, $eexons, $format) = split '\t', $_;
	
	#my $base = undef; # defined in each search type.

	#my $info = {};	
	#$info->{family} = $family;
	#$info->{organism} = $organism;
	#$info->{strain} = $strain;
	
	#print STDERR "searching for ...\n";
	#print STDERR "organism: $organism\n";
	#print STDERR "strain: $strain\n";
	#print STDERR "family: $family\n";

	# create directories.
	#my $outdir = "$OUTDIR/".$info->super_family;
	#if (! -d $outdir) {
	#	mkdir $outdir;
	#}
	#chdir $outdir;

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
	
	# parse results.
	#print STDERR "parsing results ... ";
	#system "hmmer_parse.pl -i $base-protein\_ls.log -e $hmm_eval > $base-protein\_ls.list";
	#system "hmmer_parse.pl -i $base-protein\_fs.log -e $hmm_eval > $base-protein\_fs.list";
	#print STDERR "OK\n";
	
	## 1.3 search with hmmsearch in gene-trans.
	#print STDERR "searching with Pfam models in nucleotide database ... ";
	#system "hmmsearch $ls.hmm $GENOMEDB/$organism_dir/gene-trans.fa > $base-gene\_ls.log";
	#system "hmmsearch $fs.hmm $GENOMEDB/$organism_dir/gene-trans.fa > $base-gene\_fs.log";
	#print STDERR "OK\n";
	
	# parse results.
	#print STDERR "parsing results ... ";
	#system "hmmer_parse.pl -i $base-gene\_ls.log -e $hmm_eval > $base-gene\_ls.list";
	#system "hmmer_parse.pl -i $base-gene\_fs.log -e $hmm_eval > $base-gene\_fs.list";
	#print STDERR "OK\n";
	
	# TODO:
	# check for genes with multiple matches (with different offset/revcom) and
	# create an unified list for sequence retrieval? 
	#
	# 1.4 do genewisedb for search with hmm in nucleotide database.
	print STDERR "* searching nucleotide database (genewisedb) ... ";
	system "genewisedb -quiet -hmmer $ls.hmm $GENOMEDB/$organism_dir/gene.fa > $base-gene\_ls-genewise.log";
	system "genewisedb -quiet -hmmer $fs.hmm $GENOMEDB/$organism_dir/gene.fa > $base-gene\_fs-genewise.log";
	print STDERR "OK\n";
	# parse results.
	#print STDERR "parsing results ... ";
	#system "genewise_parse.pl $base-gene\_ls-genewise.log > #$base-gene\_ls-genewise.list";
	#system "genewise_parse.pl $base-gene\_fs-genewise.log > $base-gene\_fs-genewise.list";
	#print STDERR "OK\n";
	
	###########################################################
	## 2. do psi-blast find best protein hits and get pssm.
	# get seed from hmmer search.
	
	# the best seed would be the best hit in the Pfam_ls search.
	# TODO: check that it is indeed a suitable seed (e-value/score).
	# if no suitable seed found, use the one provided in the config file.
	#my $list = parse_list_file("$base-protein\_ls.list");
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
	#print STDERR "parsing results ... ";
	#system "blast_parse.pl -i $base.blastpgp -e $psi_eval > $base-protein.list";
	#print STDERR "OK\n";

	#####################################################
	## 3. do psitblastn and find best nuclotide hits.
	# search in nucleotide database with psitblastn.
	print STDERR "* searching nucleotide database (psitblastn) ... ";
	system "blastall -p psitblastn -d $GENOMEDB/$organism_dir/gene -i $seedfile -R $base.chk -b 10000 > $base.psitblastn";
	print STDERR "OK\n";
	#print STDERR "parsing results ... ";
	#system "blast_parse.pl -i $base.psitblastn -e $tbn_eval > $base-gene.list";
	#print STDERR "OK\n";
}
#close IN;

#sub get_random_dir {
#	my @time = localtime time;
#	$time[5] += 1900;
#	$time[4] ++;
#	$time[4] = sprintf("%02d", $time[4]);
#	$time[3] = sprintf("%02d", $time[3]);
#	$time[2] = sprintf("%02d", $time[2]);
#	$time[1] = sprintf("%02d", $time[1]);
#	$time[0] = sprintf("%02d", $time[0]);
	
#	return "$time[5]$time[4]$time[3].$time[2]$time[1]$time[0]";
#}
