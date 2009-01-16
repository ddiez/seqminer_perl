#!/usr/bin/env perl

use strict;
use warnings;

use varDB::Config;

my $file = shift;
my $my_family = shift;

my $VARDBHOME = $varDB::Config::VARDBHOME;
my $GENOMEDB = $varDB::Config::GENOMEDB;
my $HMMDB = $varDB::Config::HMMDB;
my $OUTDIR = "$VARDBHOME/tmp/genomes";

if (! -d $OUTDIR) {
	mkdir $OUTDIR;
}

open IN, "$file" or die "$!";
while (<IN>) {
	chomp;
	
	/^#/ && do { print "skipping line $_\n"; next; };
	
	my ($family, $organisms, $hmm) = split '\t', $_;

	my $hmmfile = "$HMMDB/$hmm.hmm";

	if (defined $my_family and $my_family eq $family) {
		print STDERR "searching for family $family ...\n";
	
		# TODO: check for directory presence at take appropriate measures,
		# meanwhile just make a clean analysis.
		my $outdir = "$OUTDIR/$family";
		if (-d $outdir) {
			system "rm -rf $outdir"
		}
		mkdir $outdir;
		chdir $outdir;
		
		foreach my $genome (split ';', $organisms) {
			print STDERR "genome $genome ... ";
			my $outfile = "$family-$genome";
			my $genomefile = "$GENOMEDB/$genome/$genome-protein";
			system "hmmsearch $hmmfile $genomefile.fa > $outfile.log 2>>log";
			system "hmmer_parse.pl -i $outfile.log -e 1E-2 > $outfile.list 2>>log";
			system "extract_fasta.pl -f $outfile.list -i $genomefile.idx > \\
				$outfile.fa 2>>log";
			system "hmmalign -q -m -o $outfile.sto $hmmfile $outfile.fa 2>>log";
			system "quicktree -kimura -boot 100 $outfile.sto \\
				> $outfile.phb 2>>log";
			
			system "cat $outfile.list >> $family.list";
			system "cat $outfile.fa >> $family.fa";
			print STDERR "OK\n";
		}
		system "hmmalign -q -m -o $family.sto $hmmfile $family.fa 2>>log";
		system "quicktree -kimura -boot 100 $family.sto > $family.phb 2>>log";
	} else {
		print STDERR "skipping family $family\n";
	}
}
close IN;
