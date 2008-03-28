#!/usr/bin/env perl


use strict;
use warnings;

use varDB::Config;
#use varDB::Position;
use varDB::ListIO;
#use Sets;

my $file = shift;
$file = "$VARDB_HOME/etc/search_sequences.txt" if !defined $file;

print STDERR "reading config file: $file\n";

# define locations.
my $VARDB_RELEASE = 1;
my $OUTDIR = "$VARDB_HOME/families/vardb-$VARDB_RELEASE";
my $DEBUG = 1;
if ($DEBUG == 1) {
	my @time = localtime time;
	$time[5] += 1900;
	$time[4] ++;
	$time[4] = sprintf("%02d", $time[4]);
	$time[3] = sprintf("%02d", $time[3]);
	$time[2] = sprintf("%02d", $time[2]);
	$time[1] = sprintf("%02d", $time[1]);
	$time[0] = sprintf("%02d", $time[0]);

	$OUTDIR = "$VARDB_HOME/families/test/$time[5]$time[4]$time[3].$time[2]$time[1]$time[0]";
}
print STDERR "output_dir: $OUTDIR\n";

# create working directory, die on failure.
if (! -d $OUTDIR) {
	mkdir $OUTDIR;
} else {
	die "directory $OUTDIR already exists!.\n";
}

if ($DEBUG == 1) {
	unlink "$VARDB_HOME/families/test/last";
	system "ln -s $OUTDIR $VARDB_HOME/families/test/last";
}

open IN, "$file" or die "$!";
while (<IN>) {
	next if /^[#|\n]/;
	chomp;
	
	my ($organism, $strain, $organism_dir, $super, $family, $seed, $pssm_eval, $psi_eval, $tbn_eval, $iter, $hmm_acc, $hmm_name, $hmm_eval, $eexons, $format) = split '\t', $_;
	
	my $base = undef; # defined in each search type.

	my $info = {};	
	$info->{family} = $family;
	$info->{organism} = $organism;
	$info->{strain} = $strain;
	
	print STDERR "searching for ...\n";
	print STDERR "organism: $organism\n";
	print STDERR "strain: $strain\n";
	print STDERR "family: $family\n";

	# neither like this.
	my $outdir = "$OUTDIR/$super";
	if (! -d $outdir) {
		mkdir $outdir;
	}
	
	chdir $outdir;

	$base = "$family-$organism_dir";
	###################################################
	## 1. do hmmer and find the best seed possible.

	# retrieve model with hmmfetch library hmm_name.
	# use libraries Pfam_ls and Pfam_fs.
	my $fs = $hmm_name."_ls";
	my $ls = $hmm_name."_fs";
	print STDERR "fetching Pfam models ... ";
	system "hmmfetch $HMMDB/$PFAM_VERSION/Pfam_ls $hmm_name > $fs.hmm";
	system "hmmfetch $HMMDB/$PFAM_VERSION/Pfam_fs $hmm_name > $ls.hmm";
	print STDERR "OK\n";

	# search in protein genome.
	print STDERR "searching with Pfam models in protein database ... ";
	system "hmmsearch $ls.hmm $GENOMEDB/$organism_dir/protein.fa > $base-protein\_ls.log";
	system "hmmsearch $fs.hmm $GENOMEDB/$organism_dir/protein.fa > $base-protein\_fs.log";
	print STDERR "OK\n";
	
	# parse results.
	print STDERR "parsing results ... ";
	system "hmmer_parse.pl -i $base-protein\_ls.log -e $hmm_eval > $base-protein\_ls.list";
	system "hmmer_parse.pl -i $base-protein\_fs.log -e $hmm_eval > $base-protein\_fs.list";
	print STDERR "OK\n";
	
	# the best seed would be the best hit in the Pfam_ls search.
	# TODO: check that it is indeed a suitable seed (e-value/score).
	# if no suitable seed found, use the one provided in the config file.
	#my $list = parse_list_file("$base-protein\_ls.list");
	my $list = new varDB::ListIO({file => "$base-protein\_ls.list"});
	$seed = $list->get_id(0);
	#$seed = $list->{gene_list}->[0];
	
	## 1.3 search with hmmsearch in gene-trans.
	print STDERR "searching with Pfam models in nucleotide database ... ";
	system "hmmsearch $ls.hmm $GENOMEDB/$organism_dir/gene-trans.fa > $base-gene\_ls.log";
	system "hmmsearch $fs.hmm $GENOMEDB/$organism_dir/gene-trans.fa > $base-gene\_fs.log";
	print STDERR "OK\n";
	
	# parse results.
	print STDERR "parsing results ... ";
	system "hmmer_parse.pl -i $base-gene\_ls.log -e $hmm_eval > $base-gene\_ls.list";
	system "hmmer_parse.pl -i $base-gene\_fs.log -e $hmm_eval > $base-gene\_fs.list";
	print STDERR "OK\n";
	
	# TODO:
	# check for genes with multiple matches (with different offset/revcom) and
	# create an unified list for sequence retrieval? 
	
	###########################################################
	## 2. do psi-blast find best protein hits and get pssm.
	# get seed from hmmer search.
	my $seedfile = "$family-$organism_dir.seed";
	system "extract_fasta.pl -d $seed -i $GENOMEDB/$organism_dir/protein.idx > $seedfile";
	
	# search in protein database with psi-blast and generate pssm file.
	print STDERR "searching with PSI-Blast in protein database ... ";
	system "blastpgp -d $GENOMEDB/$organism_dir/protein -i $seedfile -s T -j $iter -h $pssm_eval -C $base.chk -F T -b 10000  > $base.blastpgp";
	print STDERR "OK\n";
	# write psi-blast report.
	system "psiblast_report.pl -i $base.blastpgp -e $pssm_eval > $base-cycles.txt";
	print STDERR "parsing results ... ";
	system "blast_parse.pl -i $base.blastpgp -e $psi_eval > $base-protein.list";
	print STDERR "OK\n";

	#####################################################
	## 3. do psitblastn and find best nuclotide hits.
	# search in nucleotide database with psitblastn.
	print STDERR "searching with Blast-psitblastn in nucleotide database ... ";
	system "blastall -p psitblastn -d $GENOMEDB/$organism_dir/gene -i $seedfile -R $base.chk -b 10000 > $base.psitblastn";
	print STDERR "OK\n";
	print STDERR "parsing results ... ";
	system "blast_parse.pl -i $base.psitblastn -e $tbn_eval > $base-gene.list";
	print STDERR "OK\n";
}
close IN;
