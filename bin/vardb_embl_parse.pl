#!/usr/bin/env perl

use strict;
use warnings;
#
#  This is the main script for parsing data comming from GeneDB. This parser is
#  meant to be used with the EMBL file formats. This script generates 4
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
#  This is the main script for parsing data comming from GeneDB. This parser is
#  meant to be used with the EMBL file formats. This script generates 4
#  files: genome.gff, genome.fa, gene.fa and protein.fa formated for use in
#  the SeqMiner project.
#!! WARNING !!

    vardb_embl_parse.pl -i <file>

HELP



my $in = new Bio::SeqIO( -file => shift, -format => 'EMBL' );

my $genome = new SeqMiner::Genome;
$genome->organism("Trypanosoma brucei");
my $current_chr = undef;
my $noid = 0;
my $trna_noid = 0;
while ( my $seq = $in->next_seq ) {
	my @feat = $seq->get_all_SeqFeatures;
	for my $feat (@feat) {
		# chromosomes.
		if ($feat->primary_tag eq "source") {
			#print STDERR "found one source... ";
			if ($feat->has_tag("so_type")) {
				my @type = $feat->get_tag_values("so_type");
				#print STDERR "$type[0]\n";
				if ($type[0] eq "chromosome") {
					print STDERR "chromosome: ";
					if ($feat->has_tag("systematic_id")) {
						#print STDERR "has a systematic id... ";
						my $id = ($feat->get_tag_values("systematic_id"))[0];
						print STDERR "$id\n";
						my $seq = $feat->seq;
						#print STDERR "seq: ", $seq->display_id, "\n";
						#$seq->display_id($id);
						#print STDERR "seq: ", $seq->display_id, "\n";
						my $chr = new SeqMiner::Genome::Chromosome;
						$chr->id($id);
						$chr->seq($seq->seq);
						$genome->add_chromosome($chr);
						$current_chr = $id;
						#$genome_out->write_seq($seq);
					}
				}
			}
		}

		# genes.
		if ($feat->primary_tag eq "CDS") {
			if ($feat->has_tag("systematic_id")) {
				my $id = ($feat->get_tag_values("systematic_id"))[0];
				my $product = ($feat->get_tag_values("product"))[0] if $feat->has_tag("product");
				my $pseudo = 0;
				$pseudo = 1 if $feat->has_tag("pseudo");
				my $seq = $feat->seq;
				
				my $gene = new SeqMiner::Genome::Gene;
				$gene->id($id);
				$gene->source("genedb");
				$gene->start($feat->start);
				$gene->end($feat->end);
				$gene->seq($seq->seq);
				$gene->strand($feat->strand == 1 ? "+" : "-");
				$gene->chromosome($current_chr);
				$gene->pseudogene(1) if $feat->has_tag('pseudo');
				$gene->description($product);
				$gene->translation($seq->translate) if ! $gene->pseudogene;
				$genome->add_gene($gene);
				
				#$gene_out->write_seq($seq);
				#$prot_out->write_seq($seq->translate) unless $pseudo;
				
			} else {
				#print STDERR "WARNING: CDS without systematic id\n";
				$noid++;
			}
		}
		
		# tRNAs.
		if ($feat->primary_tag eq "tRNA") {
			if ($feat->has_tag("systematic_id")) {
				my $id = ($feat->get_tag_values("systematic_id"))[0];
				my $product = ($feat->get_tag_values("product"))[0] if $feat->has_tag("product");
				
				my $seq = $feat->seq;
					
				my $gene = new SeqMiner::Genome::Gene;
				$gene->id($id);
				$gene->source("ncbi");
				$gene->start($feat->start);
				$gene->end($feat->end);
				$gene->seq($seq->seq);
				$gene->strand($feat->strand == 1 ? "+" : "-");
				$gene->chromosome($current_chr);
				
				$gene->description($product);
				$genome->add_gene($gene);
			} else {
				$trna_noid++;
			}
		}
	}
}

print STDERR "$noid CDS features without systematic id.\n";
print STDERR "$trna_noid tRNA features without systematic id.\n";


$genome->print_fasta({file => "genome.fa", type => 'genome'});
$genome->print_fasta({file => "gene.fa", type => 'nucleotide'});
$genome->print_fasta({file => "protein.fa", type => 'protein'});
$genome->print_gff({file => "genome.gff"});