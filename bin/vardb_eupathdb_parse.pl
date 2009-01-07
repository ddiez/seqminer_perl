#!/usr/bin/env perl
#
#  This is the main script for parsing data comming from EupathDB, formel
#  known as ApiDB. This consists on sequence data from different projects
#  like PlasmoDB, ToxoDB, GiardiaDB, etc. This parser is meant to be used
#  with the EupathDB GFF file formats. These are GFF3 compliant files and
#  therefore, contain sequence features and sequence data. This script
#  generates 4 files, genome.gff, genome.fa, gene.fa and protein.fa formated
#  for use in the SeqMiner project.
#
#
use strict;
use warnings;
use Bio::Tools::GFF;
use Bio::SeqIO;
use Getopt::Long;
use SeqMiner::Genome;
use SeqMiner::SeqSet;

my %O = ();
GetOptions(\%O, 'i:s', 'o:s');

my $help = <<"HELP";

#!! WARNING !!
#  This is the main script for parsing data comming from EupathDB, formel
#  known as ApiDB. This consists on sequence data from different projects
#  like PlasmoDB, ToxoDB, GiardiaDB, etc. This parser is meant to be used
#  with the EupathDB GFF file formats. These are GFF3 compliant files and
#  therefore, contain sequence features and sequence data. This script
#  generates 4 files, genome.gff, genome.fa, gene.fa and protein.fa formated
#  for use in the SeqMiner project.
#!! WARNING !!

    vardb_eupathdb_parse.pl -i <file>

HELP

die $help if ! exists $O{i};
my $outdir = ".";
$outdir = $O{o} if exists $O{o};
print STDERR "* outdir: $outdir\n";

my $genome = new SeqMiner::Genome;

my $in = new Bio::Tools::GFF(-file => $O{i}, -gff_version => 3);
my $prot_out = new Bio::SeqIO(-file => ">$outdir/protein.fa", -format => 'fasta');
my $nuc_out = new Bio::SeqIO(-file => ">$outdir/gene.fa", -format => 'fasta');
my $gen_out = new Bio::SeqIO(-file => ">$outdir/genome.fa", -format => 'fasta');

while (my $feat = $in->next_feature) {
	if ($feat->primary_tag eq "gene") {
		my $gene = new SeqMiner::Genome::Gene;
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
		if (defined $gene and $gene->pseudogene == 0) {
			my $exon = new SeqMiner::Genome::Exon;
			$exon->id($exon_id);
			$gene->add_exon($exon);
			$exon->start($feat->start);
			$exon->end($feat->end);
			$exon->strand($feat->strand == 1 ? "+" : "-");
		}
	} elsif ($feat->primary_tag eq "supercontig") {
		my $chr = new SeqMiner::Genome::Chromosome;
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
		if ($gene->pseudogene == 0) {
			my $seq = $seq->seq;
			$seq =~ s/\*$//; # remove stop codon at the end if any.
			$gene->translation($seq);
		}
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
	$chr = $chr->trunc($gene->start, $gene->end);
	$chr = $chr->revcom if ($gene->strand eq "-");
	$gene->seq($chr->seq);
}

# output files.
$genome->print_fasta({type => "nucleotide", file => "gene.fa"});
$genome->print_fasta({type => "protein", file => "protein.fa"});
$genome->print_fasta({type => "genome", file => "genome.fa"});
$genome->print_gff({file => "genome.gff"});