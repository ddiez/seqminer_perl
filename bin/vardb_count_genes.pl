#!/usr/bin/env perl

use strict;
use warnings;

use varDB::Config;

opendir DIR, $GENOMEDB or die "Cannot opendir $GENOMEDB: $!";

foreach my $org (sort readdir DIR) {
	next if $org =~ /\./;
    #print "found file: $org\n";
	my $file = "$GENOMEDB/$org/$org-nucleotide.fa";
	open IN, $file or die "cannot open file $file: $!";
	my $n = 0;
	while (<IN>) {
		next if $_ =! />/;
		$n++;
	}
	close IN;
	print "$org\t$n\n";
}
closedir DIR;
