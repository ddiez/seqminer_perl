#!/usr/bin/env perl

use strict;
use warnings;

use varDB::Config;

my $file = shift;

my $VARDBHOME = $varDB::Config::VARDBHOME;
my $GENOMEDB = $varDB::Config::GENOMEDB;
my $UNIPROTDB = $varDB::Config::UNIPROTDB;
my $OUTDIR = "$VARDBHOME/families/uniprot";

if (! -d $OUTDIR) {
	mkdir $OUTDIR;
}
unlink "$OUTDIR/uniprot-number.txt";

open IN, "$file" or die "$!";
while (<IN>) {
	chomp;
	
	/^#/ && do { print "skipping line $_\n"; next; };
	
	my ($super, $organism, $family, $seed, $hmm) = split '\t', $_;

	print STDERR "searching for family $family in Uniprot ... ";

	my $outdir = "$OUTDIR/$super";
	if (! -d $outdir) {
		mkdir $outdir;
	}
	#$outdir .= "/$family-$organism";
	#mkdir $outdir;
	chdir $outdir;

	# get seed sequence:
	system "extract_fasta.pl -d $seed -i $GENOMEDB/$organism/$organism-protein.idx > $family.seed";

	# search with PSI-Blast and generate pssm file.
	system "blastpgp -d $UNIPROTDB/$organism/$organism-protein -i $family.seed -s T -j 10 -h 0.001 -C $family-$organism.chk -F T > $family-$organism.blastpgp";

	
	# get list of ids.
	system "blast_parse.pl -i $family-$organism.psitblastn -e 0.01 > $family-$organism-nucleotide.list";
	system "blast_parse.pl -i $family-$organism.blastpgp -e 0.01 > $family-$organism-protein.list";
	
	# count number of sequences obtained.
	system "vardb_count_list.pl $family-$organism-nucleotide.list \"$family\t$organism\tnucleotide\">> $OUTDIR/number.txt";
	system "vardb_count_list.pl $family-$organism-protein.list \"$family\t$organism\tprotein\">> $OUTDIR/uniprot-number.txt";

	# get fasta files.
	system "extract_fasta.pl -f $family-$organism-nucleotide.list -i $GENOMEDB/$organism/$organism-nucleotide.idx > $family-$organism-nucleotide.fa";
	system "extract_fasta.pl -f $family-$organism-protein.list -i $GENOMEDB/$organism/$organism-protein.idx > $family-$organism-protein.fa";


	#system "hmmalign -q -m -o $family.sto $hmmfile $family.fa 2>>log";
	#system "quicktree -kimura -boot 100 $family.sto > $family.phb 2>>log";
	print STDERR "OK\n";
}
close IN;
