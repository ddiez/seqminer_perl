#!/usr/bin/env perl

use varDB::Genome;
use Bio::SeqIO;
use strict;
use warnings;


my $in = new Bio::SeqIO(-file => shift, -format => 'embl');

while (my $seq = $in->next_seq) {
	# in bacterial genomes that would be just one sequence.
	print STDERR "id: ", $seq->accession_number, "\n";
	print STDERR "id: ", $seq->display_name, "\n";
	my $genome = new varDB::Genome;

	my @feat = $seq->get_SeqFeatures(); # just top level
	foreach my $feat (@feat) {
		# try to parse chromosomes.
		if ($feat->primary_tag eq "source") {
			if ($feat->has_tag('origid')) {
				print STDERR $feat->get_tag_values('origid'), "\n";
				print STDERR $feat->start, "\t", $feat->end, "\n";
			}
		}
		
		if ($feat->primary_tag eq "CDS") {
			my $gene = new varDB::Gene();
			$gene->set_id($feat->get_tag_values('systematic_id'));
			$gene->set_source("genedb");
			$gene->set_chromosome("-");
			$gene->set_strand($feat->strand eq "1" ? "+" : "-");
			$gene->set_start($feat->start);
			$gene->set_end($feat->end);
			$gene->set_description($feat->get_tag_values('product'));
			
			$genome->add_gene($gene);
			
			my @loc = $feat->location->each_Location;
			foreach my $loc (@loc) {
				my $gene_ = $genome->get_gene($gene->get_id);
				my $exon = new varDB::Exon;
				$exon->set_id($gene_->get_nexons + 1);
				$exon->set_parent($gene_->get_id);
				$exon->set_strand($gene_->get_strand);
				$exon->set_start($loc->start);
				$exon->set_end($loc->end);
				
				$genome->add_exon($exon);
			}
		}
	}
	$genome->print_gff;
}
