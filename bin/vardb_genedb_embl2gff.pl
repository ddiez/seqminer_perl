#!/usr/bin/env perl

use varDB::Genome;
use Bio::SeqIO;
use strict;
use warnings;

unlink "genome.fa" if (-e "genome.fa");
unlink "genome.gff" if (-e "genome.gff");

my $in = new Bio::SeqIO(-file => shift, -format => 'embl');
my $out_g = new Bio::SeqIO(-file => '>>genome.fa', -format => 'fasta');

my $n = 0;
while (my $seq = $in->next_seq) {
	$n++;
	print STDERR "* seq $n\n";
	
	# in bacterial genomes that would be just one sequence.
	my $genome = new varDB::Genome;
	my $chr = "-";
	
	my @feat = $seq->get_SeqFeatures; # just top level
	foreach my $feat (@feat) {
		# try to parse chromosomes.
		if ($feat->primary_tag eq "source") {
			print STDERR "- found source tag ...\n";
			# skip if no chromosome.
			# TODO: what to do with those??
			if ($feat->has_tag('so_type')) {
				if (($feat->get_tag_values('so_type'))[0] eq 'chromosome') {
					print STDERR "- found chromosome tag ...\n";
					if ($feat->has_tag('systematic_id')) {
						print STDERR "- found systematic_id ...\n";
						$chr = ($feat->get_tag_values('systematic_id'))[0];
						$seq->display_id($chr);
						print STDERR "* chromosome: $chr\n";
					}
				}
			} else {
				print STDERR ".. skipped\n";
			}
		}
		
		if ($feat->primary_tag eq "CDS") {
			my $gene = new varDB::Genome::Gene;
			if ($feat->has_tag('systematic_id')) {
				$gene->id($feat->get_tag_values('systematic_id'));
			} else {
				$gene->id("args");
			}
			$gene->source("genedb");
			$gene->chromosome($chr);
			$gene->strand($feat->strand eq "1" ? "+" : "-");
			$gene->start($feat->start);
			$gene->end($feat->end);
			$gene->description($feat->get_tag_values('product'));
			
			$genome->add_gene($gene);
			
			my @loc = $feat->location->each_Location;
			foreach my $loc (@loc) {
				my $gene_ = $genome->get_gene_by_id($gene->id);
				my $exon = new varDB::Genome::Exon;
				$exon->id($gene_->nexons + 1);
				$exon->parent($gene_->id);
				$exon->strand($gene_->strand);
				$exon->start($loc->start);
				$exon->end($loc->end);
				
				$genome->add_exon($exon);
			}
		}
	}
	
	$out_g->write_seq($seq);
	$genome->print_gff({file => '>>genome.gff'});
}
