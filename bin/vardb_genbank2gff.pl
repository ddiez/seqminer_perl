#!/usr/bin/env perl

use varDB::Genome;
use Bio::SeqIO;
use strict;
use warnings;


my $in = new Bio::SeqIO(-file => shift, -format => 'genbank');

while (my $seq = $in->next_seq) {
	# in bacterial genomes that would be just one sequence.
	print STDERR "id: ", $seq->accession_number, "\n";
	print STDERR "circular: ", $seq->is_circular, "\n";
	print STDERR "desc: ", $seq->description, "\n";
	my $species = $seq->species;
	print STDERR "species: ", $species->species, "\n";

	my $genome = new varDB::Genome;
	$genome->set_organism($seq->species);
	
	my @feat = $seq->get_SeqFeatures; # just top level
    foreach my $feat (@feat) {
		next if $feat->primary_tag eq "source";
		if ($feat->primary_tag eq "gene") {
			my $gene = new varDB::Gene;
			$gene->set_id($feat->get_tag_values('locus_tag'));
			$gene->set_source("ncbi");
			$gene->set_start($feat->start);
			$gene->set_end($feat->end);
			$gene->set_strand($feat->strand == 1 ? "+" : "-");
			$gene->set_chromosome($seq->accession_number);
			if ($feat->has_tag('pseudo') && $feat->has_tag('note')) {
				$gene->set_description($feat->get_tag_values('note'));
			} else {
				$gene->set_description("");
			}
			$genome->add_gene($gene);
		} elsif ($feat->primary_tag eq "CDS") {
			my $gene = $genome->get_gene($feat->get_tag_values('locus_tag'));
			$gene->set_description($feat->get_tag_values('product'));
			
			my $exon = new varDB::Exon;
			$exon->set_id($gene->get_nexons + 1);
			$exon->set_parent($gene->get_id);
			$exon->set_start($feat->start);
			$exon->set_end($feat->end);
			$exon->set_strand($feat->strand == 1 ? "+" : "-");
			$genome->add_exon($exon);
		} elsif ($feat->primary_tag eq "tRNA") {
			my $gene = $genome->get_gene($feat->get_tag_values('locus_tag'));
			$gene->set_description($feat->get_tag_values('product'));
			
			my $exon = new varDB::Exon;
			$exon->set_id($gene->get_nexons + 1);
			$exon->set_parent($gene->get_id);
			$exon->set_start($feat->start);
			$exon->set_end($feat->end);
			$exon->set_strand($feat->strand == 1 ? "+" : "-");
			$genome->add_exon($exon);
		}
    }
	$genome->print_gff;
}

