#!/usr/bin/env perl

use strict;
use warnings;

use varDB::Config;

my $file = shift;

my $VARDBHOME = $varDB::Config::VARDBHOME;
my $GENOMEDB = $varDB::Config::GENOMEDB;
my $OUTDIR = "$VARDBHOME/families/test";

if (! -d $OUTDIR) {
	mkdir $OUTDIR;
}

open IN, "$file" or die "$!";
while (<IN>) {
	chomp;
	
	/^#/ && do { print "skipping line $_\n"; next; };
	
	my ($super, $organism, $family, $seed, $pssm_eval, $psi_eval, $tbn_eval, $iter, $hmm) = split '\t', $_;
	
	my $base = "$family-$organism";

	print STDERR "searching for family $family in $organism ... ";

	my $outdir = "$OUTDIR/$super";
	if (! -d $outdir) {
		mkdir $outdir;
	}
	#$outdir .= "/$family-$organism";
	#mkdir $outdir;
	chdir $outdir;

	# get seed sequence:
	system "extract_fasta.pl -d $seed -i $GENOMEDB/$organism/$organism-protein.idx > $base.seed";

	# search in protein database with psi-blast and generate pssm file.
	system "blastpgp -d $GENOMEDB/$organism/$organism-protein -i $base.seed -s T -j $iter -h $pssm_eval -C $base.chk -F T -b 10000  > $base.blastpgp";
	# write psi-blast report.
	system "psiblast_report.pl -i $base.blastpgp -e $pssm_eval > $base-cycles.txt";

	# search in nucleotide database with psitblastn.
	system "blastall -p psitblastn -d $GENOMEDB/$organism/$organism-nucleotide -i $base.seed -R $base.chk -b 10000 > $base.psitblastn";
	
	# get list of ids.
	system "blast_parse.pl -i $base.psitblastn -e $tbn_eval > $base-nucleotide.list";
	system "blast_parse.pl -i $base.blastpgp -e $psi_eval > $base-protein.list";
	
	# count number of sequences obtained.
	system "vardb_count_list.pl $base-nucleotide.list \"$family\t$organism\tnucleotide\" > $base-number.txt";
	system "vardb_count_list.pl $base-protein.list \"$family\t$organism\tprotein\" >> $base-number.txt";
	
	# get fasta files.
	system "extract_fasta.pl -f $base-nucleotide.list -i $GENOMEDB/$organism/$organism-nucleotide.idx > $base-nucleotide.fa";
	system "extract_fasta.pl -f $base-protein.list -i $GENOMEDB/$organism/$organism-protein.idx > $base-protein.fa";


	#system "hmmalign -q -m -o $family.sto $hmmfile $family.fa 2>>log";
	#system "quicktree -kimura -boot 100 $family.sto > $family.phb 2>>log";
	print STDERR "OK\n";
}
close IN;
