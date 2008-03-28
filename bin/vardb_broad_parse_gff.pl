#!/usr/bin/env perl

use varDB::Genome;
use strict;
use warnings;

my $genome = new varDB::Genome();
my $file = shift;
open IN, $file or die "ERROR: cannot open file $file: $!\n";
while (<IN>) {
	chomp;
	my ($id, $source, $type, $start, $end, $foo, $strand, $foo2, $info) = split '\t', $_;
	my $chr = $1 if $id =~ /(supercont\d\.\d+).+/;
	if ($type eq "start_codon") {
		$info = parse_gene_info($info);
		my $gene = new varDB::Gene($info);
		$gene->set_strand($strand);
		$gene->set_start($start);
		$gene->set_chromosome($chr);
		$gene->set_description("");
		$genome->add_gene($gene);
	} elsif ($type eq "stop_codon") {
		$info = parse_info($info);
		my $gene = $genome->get_gene($info->{id});
		$gene->set_end($end);
	} elsif ($type eq "exon") {
		$info = parse_exon_info($info);
		my $gene = $genome->get_gene($info->{parent});
		if (defined $gene) {
			$info->{id} = $gene->get_nexons() + 1;
			my $exon = new varDB::Exon($info);
			$exon->set_strand($strand);
			$exon->set_start($start);
			$exon->set_end($end);
			$genome->add_exon($exon);
		}
	} # skip the rest.
}
close IN;

$genome->print_gff;

sub parse_info {
	my $tmp = shift;
	my $info = {};
	$tmp =~ /^gene_id "(.+?)"; transcript_id "(.+?)";/;
	$info->{id} = $1;
	return $info;
}

sub parse_gene_info {
	my $tmp = shift;
	return parse_info($tmp);
} 

sub parse_exon_info {
	my $tmp = shift;
	my $info = parse_info($tmp);
	$info->{parent} = $info->{id};
	$info->{id} = undef;
	return $info;
}
