#!/usr/bin/env perl

use strict;
use warnings;

use varDB::Config;

my $file = shift;
my $my_family = shift;

my $VARDBHOME = $varDB::Config::VARDBHOME;
my $UNIPROTDB = $varDB::Config::UNIPROTDB;
my $HMMDB = $varDB::Config::HMMDB;
my $OUTDIR = "$VARDBHOME/tmp/uniprot";

if (! -d $OUTDIR) {
	#mkdir $OUTDIR;
	die "ERROR: $OUTDIR not exists!";
}

open IN, "$file" or die "$!";
while (<IN>) {
	chomp;
	
	/^#/ && do { print "skipping line $_\n"; next; };
	
	my ($family, $organisms, $hmm) = split '\t', $_;
	my $hmmfile = "$HMMDB/$hmm.hmm";

	if (defined $my_family && $my_family eq $family) {
		print STDERR "searching family $family ...\n";

		my $outdir = "$OUTDIR/$family";
		# TODO: check for directory existence an take appropriate measure-
		# ments. meanwhile, just make clean installation.
		#if (-d $outdir) {
			#system "rm -rf $outdir";
		#}
		#mkdir $outdir;
		if (! -d $outdir) {
			mkdir $outdir
		}
		chdir $outdir;

		my @files = ("uniprot_sprot", "uniprot_trembl");
		#my @files = ("uniprot_sprot");
		#my @files = ("uniprot_trembl");

		foreach my $file (@files) {
			print STDERR "$file ...";
			my $outfile = "$family-$file";
			my $infile = "$UNIPROTDB/$file";

			system "hmmsearch $hmmfile $infile.fasta > $outfile.log 2>>log";
			system "hmmer_parse.pl -i $outfile.log -e 1E-2 \\
				> $outfile.list 2>>log";
			system "extract_fasta.pl -f $outfile.list -i $infile.idx > \\
				$outfile.fa 2>>log";
			system "hmmalign -q -m -o $outfile.sto $hmmfile $outfile.fa \\
				2>>log";
			system "quicktree -kimura -boot 100 $outfile.sto \\
				> $outfile.phb 2>>log";
		}
	} else {
		print STDERR "skipping family $family\n";
	}
}
close IN;
