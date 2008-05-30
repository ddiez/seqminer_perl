#!/usr/bin/env perl

use strict;
use warnings;

use Bio::Tools::GFF;
use Getopt::Long;
use varDB::Genome;

my %O = ();
GetOptions(\%O, 'i:s');

my $help = <<"HELP";
    vardb_broad_parse.pl -i <file>
HELP

die $help if !exists $O{i};

my $genome = new varDB::Genome;

my $in = new Bio::Tools::GFF(-file => $O{i}, -gff_version => 2);
while (my $feat = $in->next_feature) {
	# !!! NOTE !!! #
	# this implementation doesn't use the start/stop codons.
	# that could be used to detect pseudogenes, i.e. an exon that doesn't
	# have start codon associated isn't a pseudogene?
	# but maybe better let the broad institute guys improve the information.
	if ($feat->primary_tag eq 'exon') {
		my $id = ($feat->get_tag_values("gene_id"))[0];
		my $gene = $genome->get_gene_by_id($id);
		
		if (! defined $gene) {
			# add the gene.
			$gene = new varDB::Genome::Gene;
			$gene->id($id);
			
			my $chr = $feat->seq_id;
			$chr =~ s/(supercont\d\.\d+).+/$1/;
			$gene->chromosome($chr);
			
			$gene->source("broad");
			
			# there is no description yet.
			#$gene->description($feat->get_tag_values("description"));
			#$gene->pseudogene(1) if $gene->description =~ /pseudogene/;
			$gene->description("");
			$gene->strand($feat->strand == 1 ? "+" : "-");
			$gene->start($feat->start);
			$gene->end($feat->end);
			
			$genome->add_gene($gene);
		}
		
		my $exon = new varDB::Genome::Exon;
		$exon->id($gene->nexons + 1);
		$exon->parent($gene->id);
		$exon->strand($feat->strand == 1 ? "+" : "-");
		
		$exon->start($feat->start);
		$exon->end($feat->end);
		$gene->start($feat->start) if $feat->start < $gene->start;
		$gene->end($feat->end) if $feat->end > $gene->end;
		
		$gene->add_exon($exon);
	}
}

$genome->print_gff;