#!/usr/bin/env perl

use SeqMiner::Genome;
use strict;
use warnings;

my $genome = new SeqMiner::Genome();
my $file = shift;

open IN, $file or die "ERROR: cannot open file $file: $!\n";
while (<IN>) {
	next if /^##/; # skip comments.
	chomp;
	my ($id, $source, $type, $start, $end, $foo, $strand, $foo2, $info) = split '\t', $_;
	my $chr = $1 if $id =~ /(.+?)\./; # no chromosome for bacteria.
	if ($type eq "gene") {
		$info = parse_gene_info($info);
		my $gene = new SeqMiner::Gene($info);
		$gene->set_strand($strand);
		$gene->set_start($start);
		$gene->set_end($end);
		$gene->set_chromosome($chr);
		$gene->set_source($source);
		$genome->add_gene($gene);
	} elsif ($type eq "exon" or $type eq "CDS") {
		$info = parse_exon_info($info);
		my $gene = $genome->get_gene($info->{parent});
		if (defined $info->{product}) {
			$gene->set_description($info->{product});
		} else {
			$gene->set_description("-");
		}
		my $exon = new SeqMiner::Exon($info);
		$exon->set_start($gene->get_start);
		$exon->set_end($gene->get_end);
		$exon->set_strand($gene->get_strand);
		$genome->add_exon($exon);
	} # skip the rest.
}
close IN;

$genome->print_gff;


sub parse_info {
	my $info = {};
	my @tokens = split ";", shift;
	foreach my $token (@tokens) {
		$token =~ /(.+)=(.+)/;
		$info->{lc $1} = $2;
	}
	$info->{id} = $info->{locus_tag};
	return $info;
}

sub parse_gene_info {
	return parse_info(shift);
} 

sub parse_exon_info {
	my $info = parse_info(shift);
	$info->{parent} = $info->{id};
	$info->{id} = 1;
	return $info;
}
