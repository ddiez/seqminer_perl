#!/usr/bin/env perl

use strict;
use warnings;

use varDB::Genome;

my $genome = new varDB::Genome;
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
		my $gene = new varDB::Genome::Gene($info);
		$gene->chromosome($chr);
		$gene->strand($strand);
		$gene->start($start);
		$gene->end($end);
		$gene->source("plasmodb");
		$genome->add_gene($gene);
	#	$gene->set_description("") if !defined $gene->get_description;
	} elsif ($type eq "exon") {
		$info = parse_exon_info($info);
		my $exon = new varDB::Genome::Exon($info);
		$exon->strand($strand);
		$exon->start($start);
		$exon->end($end);
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
	$info->{description} = _unescape($info->{description}) if exists $info->{description};
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

# from bioperl.
sub _unescape {
	my $v = shift;
	$v =~ tr/+/ /;
	$v =~ s/%([0-9a-fA-F]{2})/chr hex($1)/ge;
	return $v;
}   
