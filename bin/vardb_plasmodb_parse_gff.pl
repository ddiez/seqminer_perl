#!/usr/bin/env perl

use varDB::Genome;
use strict;
use warnings;

my $genome = new varDB::Genome();
my $file = shift;

open IN, $file or die "ERROR: cannot open file $file: $!\n";
while (<IN>) {
	last if /^##FASTA/; # skip sequences.
	next if /^##/; # skip comments.
	chomp;
	my ($id, $source, $type, $start, $end, $foo, $strand, $foo2, $info) = split '\t', $_;
	my $chr = $1 if $id =~ /apidb\|(.+)/;
	if ($type eq "gene") {
		$info = parse_gene_info($info);
		my $gene = new varDB::Gene($info);
		$gene->set_chromosome($chr);
		$gene->set_strand($strand);
		$gene->set_start($start);
		$gene->set_end($end);
		$genome->add_gene($gene);
	} elsif ($type eq "exon") {
		$info = parse_exon_info($info);
		my $exon = new varDB::Exon($info);
		$exon->set_strand($strand);
		$exon->set_start($start);
		$exon->set_end($end);
		$genome->add_exon($exon);
	} # skip other information.
}
close IN;

$genome->print_gff;


sub parse_info {
	my $tmp = shift;
	my $info = {};
	my @tokens = split ";", $tmp;
	foreach my $token (@tokens) {
		$token =~ /(.+)=(.+)/;
		$info->{lc $1} = $2;
	}
	$info->{id} =~ s/apidb\|(.+)/$1/;
	return $info;
}

sub parse_gene_info {
	my $tmp = shift;
	return parse_info($tmp);
} 

sub parse_exon_info {
	my $tmp = shift;
	my $info = parse_info($tmp);
	$info->{parent} =~ s/apidb\|rna_(.+)-.+/$1/;
	$info->{id} =~ s/exon_.+-(.+)/$1/;
	return $info;
}
