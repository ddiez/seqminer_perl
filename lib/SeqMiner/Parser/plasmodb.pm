package SeqMiner::Parser::plasmodb;

use base qw(SeqMiner::Parser);

sub new {
	my $class = shift;
	
	my $self = {};
	bless $self, $class;
    return $self;
}

sub parse {
	my $self = shift;
	
	my $file = $self->filename;
	$outdir = $self->outdir;

	use Bio::Tools::GFF;
	use Bio::SeqIO;
	use SeqMiner::Genome;
	use SeqMiner::SeqSet;
	
	my $genome = new SeqMiner::Genome;

	my $in = new Bio::Tools::GFF(-file => $file, -gff_version => 3);
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
	$genome->print_fasta({type => "nucleotide", file => "$outdir/gene.fa"});
	$genome->print_fasta({type => "protein", file => "$outdir/protein.fa"});
	$genome->print_fasta({type => "genome", file => "$outdir/genome.fa"});
	$genome->print_gff({file => "$outdir/genome.gff"});
}

1;