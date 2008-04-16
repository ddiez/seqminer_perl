#!/usr/bin/env perl

use strict;
use warnings;

use varDB::Genome;

my $genome = new varDB::Genome;
my $file = shift;
open IN, $file or die "ERROR: cannot open file $file: $!\n";
while (<IN>) {
	chomp;
	my ($id, $source, $type, $start, $end, $foo, $strand, $foo2, $info) = split '\t', $_;
	my $chr = $1 if $id =~ /(supercont\d\.\d+).+/;
	if ($type eq "start_codon") {
		$info = parse_gene_info($info);
		# see if there is already a gene initialized.
		if (!defined $genome->get_gene_by_id($info->{id}) ) {
			my $gene = new varDB::Genome::Gene($info);
			$gene->strand($strand);
			$gene->start($start);
			$gene->chromosome($chr);
			$gene->description("");
			$gene->source("broad");
			$genome->add_gene($gene);
		} else {
			# do some checks?
		}
	} elsif ($type eq "stop_codon") {
		$info = parse_info($info);
		my $gene = $genome->get_gene_by_id($info->{id});
		$gene->end($end);
	} elsif ($type eq "exon") {
		$info = parse_exon_info($info);
		my $gene = $genome->get_gene_by_id($info->{parent});
		if (defined $gene) {
			$info->{id} = $gene->nexons() + 1;
			my $exon = new varDB::Genome::Exon($info);
			$exon->strand($strand);
			$exon->start($start);
			$exon->end($end);
			$gene->add_exon($exon);
			#$genome->add_exon($exon);
		} else { # ok try to fix this mess.
			my $gene = new varDB::Genome::Gene;
			$gene->id($info->{parent});
			$gene->strand($strand);
			$gene->start($start);
			$gene->end($end);
			$gene->chromosome($chr);
			$gene->description("");
			$gene->source("broad");
			$genome->add_gene($gene);
			
			$info->{id} = 1;
			my $exon = new varDB::Genome::Exon($info);
			$exon->strand($strand);
			$exon->start($start);
			$exon->end($end);
			$gene->add_exon($exon);
			#$genome->add_exon($exon);
		}
	} # skip the rest.
}
close IN;

$genome->debug;
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
