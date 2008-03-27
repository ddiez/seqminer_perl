#!/usr/bin/env perl

use strict;
use warnings;

use varDB::Config;
use varDB::Position;
use varDB::ListIO;
use Sets;

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

open IN, "$file" or die "$!";
while (<IN>) {
	# skip blank and comment lines.
	#/^[#|\n]/ && do {
	#	next;
	#};
	next if /^[#|\n]/;
	chomp;
	
	my ($super, $organism, $family, $seed, $pssm_eval, $psi_eval, $tbn_eval, $iter, $hmm_acc, $hmm_name, $hmm_eval, $eexons, $format) = split '\t', $_;
	
	my $base = undef; # defined in each search type.

	my $info = {};	
	$info->{family} = $family;
	$info->{organism} = $organism;
	$info->{super} = $super;
	
	print STDERR "searching for ...\n";
	print STDERR "family: $family\n";
	print STDERR "organism: $organism\n";

	# neither like this.
	my $outdir = "$OUTDIR/$super";
	if (! -d $outdir) {
		mkdir $outdir;
	}
	#$outdir .= "/$family-$organism";
	#mkdir $outdir;
	chdir $outdir;

	open NUMBER, ">>number.txt" or die "$!";
	#unlink "$family-number.txt";
	
	$base = "$family-$organism";
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
	system "hmmsearch $ls.hmm $GENOMEDB/$organism/protein.fa > $base-protein\_ls.log";
	system "hmmsearch $fs.hmm $GENOMEDB/$organism/protein.fa > $base-protein\_fs.log";
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
	system "hmmsearch $ls.hmm $GENOMEDB/$organism/gene-trans.fa > $base-gene\_ls.log";
	system "hmmsearch $fs.hmm $GENOMEDB/$organism/gene-trans.fa > $base-gene\_fs.log";
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
	my $seedfile = "$family-$organism.seed";
	system "extract_fasta.pl -d $seed -i $GENOMEDB/$organism/protein.idx > $seedfile";
	
	# search in protein database with psi-blast and generate pssm file.
	print STDERR "searching with PSI-Blast in protein database ... ";
	system "blastpgp -d $GENOMEDB/$organism/protein -i $seedfile -s T -j $iter -h $pssm_eval -C $base.chk -F T -b 10000  > $base.blastpgp";
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
	system "blastall -p psitblastn -d $GENOMEDB/$organism/gene -i $seedfile -R $base.chk -b 10000 > $base.psitblastn";
	print STDERR "OK\n";
	print STDERR "parsing results ... ";
	system "blast_parse.pl -i $base.psitblastn -e $tbn_eval > $base-gene.list";
	print STDERR "OK\n";
	
	####################################################################
	## 4. do QUALITY CHECK
	
	# read position file.
	my $pos = new varDB::Position({file => "$GENOMEDB/$organism/position.txt", format => $format});
	
	# read list file.
	my $lp = new varDB::ListIO({file => "$base-protein.list"});
	my $lg = new varDB::ListIO({file => "$base-gene.list"});
	my $lp_ls = new varDB::ListIO({file => "$base-protein_ls.list"});
	my $lp_fs = new varDB::ListIO({file => "$base-protein_fs.list"});
	my $lg_ls = new varDB::ListIO({file => "$base-gene_ls.list"});
	my $lg_fs = new varDB::ListIO({file => "$base-gene_fs.list"});
	
	my $np = $lp->get_number;
	my $ng = $lg->get_number;
	my $np_ls = $lp_ls->get_number;
	my $np_fs = $lp_fs->get_number;
	my $ng_ls = $lg_ls->get_number;
	my $ng_fs = $lg_fs->get_number;
	
	# compute sets stuff.
	my $pset = new Sets($lp->get_gene_list, $lp_ls->get_gene_list, $lp_fs->get_gene_list);
	my $gset = new Sets($lg->get_gene_list, $lg_ls->get_gene_list(1), $lg_ls->get_gene_list(1));
	
	my $pi = $pset->intersect;
	my $pu = $pset->union;
	my $npi = $pi->get_items(0);
	my $npu = $pu->get_items(0);
	
	my $gi = $gset->intersect;
	my $gu = $gset->union;
	my $ngi = $gi->get_items(0);
	my $ngu = $gu->get_items(0);
	
	print STDERR << "OUT";
organism:    $organism
family:      $family
np_ls:       $np_ls
np_fs:       $np_fs
ng_ls:       $ng_ls
ng_fs:       $ng_fs
np-psi:      $np
ng-psi:      $ng
p union:     $npu
p intersect: $npi
g union:     $ngu
g intersect: $ngi
OUT

	# print number of sequences.
	print NUMBER "$np\t$family\t$organism\tprotein\n";
	print NUMBER "$ng\t$family\t$organism\tgene\n";
	print NUMBER "$np_ls\t$family\t$organism\tprotein_ls\n";
	print NUMBER "$np_fs\t$family\t$organism\tprotein_fs\n";
	print NUMBER "$ng_ls\t$family\t$organism\tgene_ls\n";
	print NUMBER "$ng_fs\t$family\t$organism\tgene_fs\n";
	print NUMBER "$npu\t$family\t$organism\tprotein union\n";
	print NUMBER "$npi\t$family\t$organism\tprotein intersect\n";
	print NUMBER "$ngu\t$family\t$organism\tgene union\n";
	print NUMBER "$ngi\t$family\t$organism\tgene intersect\n";
	
	# check exons.
	$lp->check_exons($eexons, $pos, 0);
	$lg->check_exons($eexons, $pos, 0);
	$lp_ls->check_exons($eexons, $pos, 0);
	$lp_fs->check_exons($eexons, $pos, 0);
	$lg_ls->check_exons($eexons, $pos, 1);
	$lg_fs->check_exons($eexons, $pos, 1);
	
	$lp->print;
	$lp_ls->print;
	$lp_fs->print;
	$lg->print;
	$lg_ls->print;
	$lg_fs->print;
	
	$lp->export_nelson({file => "foo.txt", info => $info});

	####################################################################
	##			
	# count number of sequences.
	# TODO: if read list file do that here.
	#system "vardb_count_list.pl $base-nucleotide.list \"$family\t$organism\tnucleotide\" >> number.txt";
	#system "vardb_count_list.pl $base-protein.list \"$family\t$organism\tprotein\" >> number.txt";
	
	# get fasta files.
	system "extract_fasta.pl -f $base-gene.list -i $GENOMEDB/$organism/gene.idx > $base-gene.fa";
	system "extract_fasta.pl -f $base-protein.list -i $GENOMEDB/$organism/protein.idx > $base-protein.fa";

	close NUMBER;
	
	###################################################################
	## 5. compute some statistics and comparisons between the different
	##    sequences obtained with hmmer and psi-blast.
}
close IN;
