#!/usr/bin/env perl
#
#  This is the main script for parsing data comming from the Broad Institute.
#  This consists on sequence data from different projects like Plasmodium
#  falciparum HB3 and DD2 strains. This parser is meant to be used
#  with the GTF and FASTA file formats. There is no single file at this point
#  that could be used to retrieve all the information. Therefore the script
#  must be run several times to obtain all the desired files. For example:
#   - vardb_broad_parse.pl -i transcripts.gtf
#   - vardb_broad_parse.pl -i supercontigs.fasta -t fasta -o genome.fa
#   - vardb_broad_parse.pl -i proteins.fasta -t fasta -o protein.fa
#   - vardb_broad_parse.pl -i genes.fasta -t fasta -o gene.fa
#
#  to get respectively genome.gff, genome.fa, gene.fa and protein.fa
#
use strict;
use warnings;

use Getopt::Long;
use varDB::Genome;

my %O = ();
GetOptions(\%O, 'i:s', 't:s', 'o:s');

my $help = <<"HELP";

#!! WARNING !!
#  This is the main script for parsing data comming from the Broad Institute.
#  This consists on sequence data from different projects like Plasmodium
#  falciparum HB3 and DD2 strains. This parser is meant to be used
#  with the GTF and FASTA file formats. There is no single file at this point
#  that could be used to retrieve all the information. Therefore the script
#  must be run several times to obtain all the desired files. For example:
#   - vardb_broad_parse.pl -i transcripts.gtf
#   - vardb_broad_parse.pl -i supercontigs.fasta -t fasta -o genome.fa
#   - vardb_broad_parse.pl -i proteins.fasta -t fasta -o protein.fa
#   - vardb_broad_parse.pl -i genes.fasta -t fasta -o gene.fa
#
#  to get respectively genome.gff, genome.fa, gene.fa and protein.fa
#!! WARNING !!

    vardb_broad_parse.pl -i <file> -t <type> -o <file>
	
	-i   input file, either fasta or gtf.
	-t   type of output (gff/fasta) [default: gff]
	-o   output file [default for gff: genome.gff/  mandatory for fasta]

HELP

die $help if ! exists $O{i};

my $type = 'gff';
$type = $O{t} if defined $O{t};

if ($type eq 'gff') {
	use Bio::Tools::GFF;
	my $in = new Bio::Tools::GFF(-file => $O{i}, -gff_version => 2);
	my $genome = new varDB::Genome;
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
	$genome->print_gff({file => exists $O{o} ? $O{o} : 'genome.gff'});
} elsif ($type eq 'fasta') {
	use Bio::SeqIO;
	die $help if ! exists $O{o};
	my $in = new Bio::SeqIO(-file => $O{i});
	my $out = new Bio::SeqIO(-file => ">$O{o}", -format => 'fasta');
	while (my $seq = $in->next_seq) {
		my $tmp = $seq->description;
		$tmp =~ /.+(Plasmodium falciparum \(isolate .+?\)) (.+)/;
		my ($org, $desc) = ($1, $2, $3);
		$seq->description($desc);
		my $seq_str = $seq->seq;
		$seq_str =~ s/\*$//; # fix protein sequences.
		$seq->seq($seq_str);
		$out->write_seq($seq);
	}
} else {
	die $help;
}