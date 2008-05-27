#!/usr/bin/env perl

use strict;
use warnings;

use varDB::Genome;
use Bio::SeqIO;
use Getopt::Long;

my %O;
GetOptions(\%O, 't:s', 'i:s');
$O{t} = "gff" if !exists $O{t};


my $in = new Bio::SeqIO(-file => $O{i}, -format => 'genbank');

while (my $seq = $in->next_seq) {
	# in bacterial genomes that would be just one sequence.
	print STDERR "* id: ", $seq->accession_number, "\n";
	print STDERR "* circular: ", $seq->is_circular, "\n";
	print STDERR "* description: ", $seq->description, "\n";
	my $species = $seq->species;
	print STDERR "* species: ", $species->species, "\n";
	
	my $genome = new varDB::Genome;
	$genome->organism($seq->species);
	
	my $chr = new varDB::Genome::Chromosome;
	$chr->id($seq->accession_number);
	$chr->seq($seq->seq);
	$genome->add_chromosome($chr);
	
	my @feat = $seq->get_SeqFeatures; # just top level
    foreach my $feat (@feat) {
		next if $feat->primary_tag eq "source";
		if ($feat->primary_tag eq "gene") {
			my $gene = new varDB::Genome::Gene;
			$gene->id($feat->get_tag_values('locus_tag'));
			$gene->source("ncbi");
			$gene->start($feat->start);
			$gene->end($feat->end);
			$gene->seq($seq->subseq($gene->start, $gene->end));
			$gene->strand($feat->strand == 1 ? "+" : "-");
			$gene->chromosome($seq->accession_number);
			if ($feat->has_tag('pseudo')) {
				$gene->pseudogene(1);
			}
			if ($feat->has_tag('pseudo') && $feat->has_tag('note')) {
				$gene->description($feat->get_tag_values('note'));
			} else {
				$gene->description("");
			}
			$genome->add_gene($gene);
		} elsif ($feat->primary_tag eq "CDS") {
			my $gene = $genome->get_gene_by_id($feat->get_tag_values('locus_tag'));
			$gene->description($feat->get_tag_values('product'));
			$gene->translation($feat->get_tag_values('translation'));
			
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
	if ($O{t} eq "gff") {
		$genome->print_gff;
	} elsif ($O{t} eq "genome") {
		$genome->print_fasta("genome");
	} elsif ($O{t} eq "protein") {
		$genome->print_fasta("protein");
	} elsif ($O{t} eq "nucleotide") {
		$genome->print_fasta("nucleotide");
	}
}

