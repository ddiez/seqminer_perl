#!/usr/bin/env perl

use strict;
use warnings;
use Bio::Tools::GFF;
use Bio::SeqIO;
use Getopt::Long;
use varDB::Genome;
use varDB::SeqSet;

my %O = ();
GetOptions(\%O, 'i:s');

my $help = <<"HELP";
    vardb_eupathdb_parse.pl -i <file>
HELP

die $help if !exists $O{i};

my $genome = new varDB::Genome;

my $in = new Bio::Tools::GFF(-file => $O{i}, -gff_version => 3);
my $prot_out = new Bio::SeqIO(-file => '>protein.fa', -format => 'fasta');
my $nuc_out = new Bio::SeqIO(-file => '>gene.fa', -format => 'fasta');
my $gen_out = new Bio::SeqIO(-file => '>genome.fa', -format => 'fasta');

while (my $feat = $in->next_feature) {
	if ($feat->primary_tag eq "gene") {
		my $gene = new varDB::Genome::Gene;
		my $chr = $feat->seq_id;
		$chr =~ s/.+\|(.+)/$1/;
		my $id = $feat->primary_id;
		$id =~ s/.+\|(.+)/$1/;
		$gene->id($id);
		$gene->chromosome($chr);
		$gene->source(lc $feat->source_tag);
		$gene->description($feat->get_tag_values("description"));
		$gene->pseudogene(1) if $gene->description =~ /pseudogene/;
		$gene->start($feat->start);
		$gene->end($feat->end);
		$gene->strand($feat->strand == 1 ? "+" : "-");
		$genome->add_gene($gene);
	} elsif ($feat->primary_tag eq "exon") {
		my $id = $feat->primary_id;
		$id =~ s/.+exon_(.+)-(.+)/$1/;
		my $exon_id = $2;
		my $gene = $genome->get_gene_by_id($id);
		if (defined $gene) {
			my $exon = new varDB::Genome::Exon;
			$exon->id($exon_id);
			$gene->add_exon($exon);
			$exon->start($feat->start);
			$exon->end($feat->end);
			$exon->strand($feat->strand == 1 ? "+" : "-");
		}
	} elsif ($feat->primary_tag eq "supercontig") {
		my $chr = new varDB::Genome::Chromosome;
		my $id = $feat->primary_id;
		$id =~ s/.+\|(.+)/$1/;
		print STDERR "* adding chromosome $id\n";
		$chr->id($id);
		$chr->description($feat->get_tag_values("description"));
		$chr->start($feat->start);
		$chr->end($feat->end);
		$genome->add_chromosome($chr);
	}
}

# get translations and supercontigs.
my @seq = $in->get_seqs;
my %SEQ;
foreach my $seq (@seq) {
	my $id = $seq->display_id;
	if ($id =~ /cds_/) {
		$id =~ s/.+cds_(.+)-.+/$1/;
		my $gene = $genome->get_gene_by_id($id);
		$gene->translation($seq->seq);
	} else {
		$id =~ s/.+\|(.+)/$1/;
		print STDERR "* searching chromosome $id\n";
		my $chr = $genome->get_chromosome_by_id($id);
		$chr->seq($seq->seq);
		$SEQ{$id} = $seq;
	}
}

# set nucleotide sequences.
foreach my $gene ($genome->gene_list) {
	my $chr_id = $gene->chromosome;
	my $chr = $SEQ{$chr_id};
	$gene->seq($chr->subseq($gene->start, $gene->end));
}

# output files.
$genome->print_fasta({type => "nucleotide", file => "gene.fa"});
$genome->print_fasta({type => "protein", file => "protein.fa"});
$genome->print_fasta({type => "genome", file => "genome.fa"});
$genome->print_gff({file => "genome.gff"});