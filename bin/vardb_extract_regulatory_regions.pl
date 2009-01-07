#!/usr/bin/env perl

use strict;
use warnings;

use SeqMiner::Config;
use SeqMiner::Config::Param;
use SeqMiner::Genome;
use SeqMiner::SeqSet;
use SeqMiner::Parser::Nelson;

my $param = new SeqMiner::Config::Param;
$param->debug;

while (my $info = $param->next_param) {
	$info->debug;
	my $family = $info->family;
	my $organism_dir = $info->organism_dir;
	my $base = "$family-$organism_dir";
	
	my $genome_gff = new SeqMiner::Genome({file => "$GENOMEDB/$organism_dir/genome.gff"});
	my $genome_fasta = new SeqMiner::SeqSet({file => "$GENOMEDB/$organism_dir/genome.fa"});

	# read the identifiers.
	$param->chdir($info, "nelson");
	my $nf = new SeqMiner::Parser::Nelson({file => "$base-nelson.txt"});
	foreach my $id ($nf->id_list) {
		# get the gene.
		my $gene = $genome_gff->get_gene_by_id($id);
		# get a subset of the genome sequence.
		my $seq = $genome_fasta->get_seq_by_id($gene->chromosome);
		print STDERR "chromosome: ", $seq->id, "\n";
		#my $subseq = $seq->subseq($gene->start, -1000, $gene->strand);
		my $subseq = $seq->subseq($gene->start, -10, $gene->strand);
		$subseq->id($gene->id);
		$subseq->print;
	}
}
