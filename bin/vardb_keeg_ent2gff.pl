#!/usr/bin/env perl
#
use Bio::SeqIO;
use varDB::Genome;

use strict;
use warnings;

my $genome = new varDB::Genome;
my $in = new Bio::SeqIO(-file => shift, -format => 'kegg');
while (my $seq = $in->next_seq) {
	my $gene = new varDB::Gene;
	$gene->set_id($seq->accession_number);
	$gene->set_source("kegg");
	$gene->set_chromosome("-");

	my @pos = $seq->annotation()->get_Annotations('position');
	my $pos = Bio::Factory::FTLocationFactory->from_string($pos[0]->text);
	$gene->set_start($pos->start);
	$gene->set_end($pos->end);
	if ($pos->strand eq "1") {
		$gene->set_strand("+");
	} else {
		$gene->set_strand("-");
	}

	my @desc = $seq->annotation->get_Annotations('description');
	$gene->set_description($desc[0]->display_text);

	$genome->add_gene($gene);

	my $exon = new varDB::Exon;
	$exon->set_id(1);
	$exon->set_parent($gene->get_id);
	$exon->set_start($gene->get_start);
	$exon->set_end($gene->get_end);
	$exon->set_strand($gene->get_strand);
	$genome->add_exon($exon);
}

$genome->print_gff;
