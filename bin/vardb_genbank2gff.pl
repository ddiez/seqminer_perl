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
	$genome->organism($seq->species);
	
	my @feat = $seq->get_SeqFeatures; # just top level
    foreach my $feat (@feat) {
		next if $feat->primary_tag eq "source";
		if ($feat->primary_tag eq "gene") {
			my $gene = new varDB::Genome::Gene;
			$gene->id($feat->get_tag_values('locus_tag'));
			$gene->source("ncbi");
			$gene->start($feat->start);
			$gene->end($feat->end);
			$gene->strand($feat->strand == 1 ? "+" : "-");
			$gene->chromosome($seq->accession_number);
			if ($feat->has_tag('pseudo') && $feat->has_tag('note')) {
				$gene->description($feat->get_tag_values('note'));
			} else {
				$gene->description("");
			}
			$genome->add_gene($gene);
		} elsif ($feat->primary_tag eq "CDS") {
			my $gene = $genome->get_gene_by_id($feat->get_tag_values('locus_tag'));
			$gene->description($feat->get_tag_values('product'));
			
			my $exon = new varDB::Genome::Exon;
			$exon->id($gene->nexons + 1);
			$exon->parent($gene->id);
			$exon->start($feat->start);
			$exon->end($feat->end);
			$exon->strand($feat->strand == 1 ? "+" : "-");
			$genome->add_exon($exon);
		} elsif ($feat->primary_tag eq "tRNA") {
			my $gene = $genome->get_gene_by_id($feat->get_tag_values('locus_tag'));
			$gene->description($feat->get_tag_values('product'));
			
			my $exon = new varDB::Genome::Exon;
			$exon->id($gene->nexons + 1);
			$exon->parent($gene->id);
			$exon->start($feat->start);
			$exon->end($feat->end);
			$exon->strand($feat->strand == 1 ? "+" : "-");
			$genome->add_exon($exon);
		}
    }
	$genome->print_gff;
}

