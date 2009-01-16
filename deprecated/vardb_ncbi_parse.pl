#!/usr/bin/env perl

use strict;
use warnings;
#
#  This is the main script for parsing data comming from NCBI. This parser is
#  meant to be used with the Genbank file formats. This script generates 4
#  files: genome.gff, genome.fa, gene.fa and protein.fa formated for use in
#  the SeqMiner project.
#
#
use SeqMiner::Genome;
use Bio::SeqIO;
use Getopt::Long;

my %O;
GetOptions(\%O, 'i:s', 'd:s');

my $help = <<"HELP";

#!! WARNING !!
#  This is the main script for parsing data comming from NCBI. This parser is
#  meant to be used with the Genbank file formats. This script generates 4
#  files: genome.gff, genome.fa, gene.fa and protein.fa formated for use in
#  the SeqMiner project.
#!! WARNING !!

Usage:

 vardb_ncbi_parse.pl -i <file> -d

Options:

   -i   file in Genbank format
   -d   directory to output data
 
HELP

die $help if !exists $O{i};

my $outdir = ".";
$outdir = $O{d} if defined $O{d};

my $in = new Bio::SeqIO(-file => $O{i}, -format => 'genbank');

my $genome = new SeqMiner::Genome;
while (my $seq = $in->next_seq) {
	# in bacterial genomes that would be just one sequence.
	print STDERR "* id: ", $seq->accession_number, "\n";
	print STDERR "* circular: ", defined $seq->is_circular ? $seq->is_circular : "undef", "\n";
	print STDERR "* description: ", $seq->description, "\n";
	print STDERR "* organism: ", $seq->species->binomial, "\n";
	
	$genome->organism($seq->species) if ! defined $genome->organism;
	
	my $chr = new SeqMiner::Genome::Chromosome;
	$chr->id($seq->accession_number);
	$chr->seq($seq->seq);
	$genome->add_chromosome($chr);
	
	my @feat = $seq->get_SeqFeatures; # just top level
    foreach my $feat (@feat) {
		if ($feat->primary_tag eq "source") {
			if ($feat->has_tag('chromosome')) {
				$chr->description($feat->get_tag_values('chromosome'));
			}
		}
		if ($feat->primary_tag eq "gene") {
			my $gene = new SeqMiner::Genome::Gene;
			$gene->id($feat->get_tag_values('locus_tag'));
			$gene->source("ncbi");
			$gene->start($feat->start);
			$gene->end($feat->end);
			$gene->seq($seq->subseq($gene->start, $gene->end));
			$gene->strand($feat->strand == 1 ? "+" : "-");
			if (defined $chr->description) {
				$gene->chromosome($chr->description);
			} else {
				$gene->chromosome($seq->accession_number);
			}
			if ($feat->has_tag('pseudo')) {
				$gene->pseudogene(1);
			}
			if ($feat->has_tag('note')) {
				$gene->description($feat->get_tag_values('note'));
			} else {
				$gene->description("");
			}
			$genome->add_gene($gene);
		} elsif ($feat->primary_tag eq "mRNA") {
			my $gene = $genome->get_gene_by_id($feat->get_tag_values('locus_tag'));
			$gene->coding_gene(1);
			$gene->description($feat->get_tag_values('product')) if $feat->has_tag('product');
		} elsif ($feat->primary_tag eq "ncRNA") {
			my $gene = $genome->get_gene_by_id($feat->get_tag_values('locus_tag'));
			$gene->coding_gene(0);
			$gene->ncrna_class($feat->get_tag_values('ncRNA_class'));
			$gene->description($feat->get_tag_values('product')) if $feat->has_tag('product');
		} elsif ($feat->primary_tag eq "CDS") {
			my $gene = $genome->get_gene_by_id($feat->get_tag_values('locus_tag'));
			$gene->description($feat->get_tag_values('product')) if $feat->has_tag('product');
			if (! $gene->pseudogene) {
				if ($feat->has_tag('translation')) {
					$gene->translation($feat->get_tag_values('translation'));
				} else {
					$gene->translation($feat->seq->translate->seq);
				}
			}
			
			for my $loc ($feat->location->each_Location) {
				my $exon = new SeqMiner::Genome::Exon;
				$exon->id($gene->nexons + 1);
				$exon->parent($gene->id);
				$exon->start($loc->start);
				$exon->end($loc->end);
				$exon->strand($feat->strand == 1 ? "+" : "-");
				$genome->add_exon($exon);
			}
			
		} elsif ($feat->primary_tag eq "tRNA") {
			my $gene = $genome->get_gene_by_id($feat->get_tag_values('locus_tag'));
			$gene->description($feat->get_tag_values('product'));
			
			my $exon = new SeqMiner::Genome::Exon;
			$exon->id($gene->nexons + 1);
			$exon->parent($gene->id);
			$exon->start($feat->start);
			$exon->end($feat->end);
			$exon->strand($feat->strand == 1 ? "+" : "-");
			$genome->add_exon($exon);
		}
    }

	$genome->print_gff({file => "$outdir/genome.gff"});
	$genome->print_fasta({file => "$outdir/genome.fa", type => 'genome'});
	$genome->print_fasta({file => "$outdir/gene.fa", type => 'nucleotide'});
	$genome->print_fasta({file => "$outdir/protein.fa", type => 'protein'});
}