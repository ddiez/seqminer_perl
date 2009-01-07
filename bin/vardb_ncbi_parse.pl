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

    vardb_ncbi_parse.pl -i <file>

HELP

die $help if !exists $O{i};

my $outdir = ".";
$outdir = $O{d} if defined $O{d};

my $in = new Bio::SeqIO(-file => $O{i}, -format => 'genbank');

#!!! NOTE !!!
# this implies one sequence (genome) per file, as everything will be dump
# to the same files.
while (my $seq = $in->next_seq) {
	# in bacterial genomes that would be just one sequence.
	print STDERR "* id: ", $seq->accession_number, "\n";
	print STDERR "* circular: ", $seq->is_circular, "\n";
	print STDERR "* description: ", $seq->description, "\n";
	my $species = $seq->species;
	print STDERR "* species: ", $species->species, "\n";
	
	my $genome = new SeqMiner::Genome;
	$genome->organism($seq->species);
	
	my $chr = new SeqMiner::Genome::Chromosome;
	$chr->id($seq->accession_number);
	$chr->seq($seq->seq);
	$genome->add_chromosome($chr);
	
	my @feat = $seq->get_SeqFeatures; # just top level
    foreach my $feat (@feat) {
		next if $feat->primary_tag eq "source";
		if ($feat->primary_tag eq "gene") {
			my $gene = new SeqMiner::Genome::Gene;
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
			
			my $exon = new SeqMiner::Genome::Exon;
			$exon->id($gene->nexons + 1);
			$exon->parent($gene->id);
			$exon->start($feat->start);
			$exon->end($feat->end);
			$exon->strand($feat->strand == 1 ? "+" : "-");
			$genome->add_exon($exon);
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