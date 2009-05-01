#!/usr/bin/env perl
use varDB::Parser::kegg;

use strict;
use warnings;

my $KEGGDIR = "/Volumes/Data/projects/vardb/db/kegg";
my $BASEDIR = "/Volumes/Data/projects/vardb/db/genomes/";

while (my $file = shift) {
	chdir $KEGGDIR;
	print STDERR "reading file: $file\n";
	my $basename = lc $file;
	$basename =~ s/(.+)\..+/$1/;
	print STDERR "basename: $basename\n";
	my $p = new varDB::Parser::kegg({file => $file, format => "kegg"});
	$p->process({dir => "$BASEDIR/$basename"});
	chdir "$BASEDIR/$basename";
	system "index_fasta.pl -i protein.fa";
	system "index_fasta.pl -i gene.fa";
	system "index_fasta.pl -i gene-trans.fa";
	system "formatdb -i protein.fa -n protein";
	system "formatdb -p F -i gene.fa -n gene";
	system "formatdb -i gene-trans.fa -n gene-trans";
}
#$p->dump("protein");
#$p->dump("location");
