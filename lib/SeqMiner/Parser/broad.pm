package SeqMiner::Parser::broad;

use base qw(SeqMiner::Parser);

sub new {
	my $class = shift;
	
	my $self = {};
	$self->{type} = undef;
	bless $self, $class;
    return $self;
}

sub type {
	my $self = shift;
	$self->{type} = shift if @_;
	return $self->{type};
}

sub parse {
	my $self = shift;
	my $type = shift;
	my $desc_file = shift;
	$self->type($type);
	$self->desc_file($desc_file);
	
	my $file = $self->filename;
	$outdir = $self->outdir;
	
	if ($type eq 'gff') {
		$self->_parse_gff;
	} elsif ($type eq 'fasta') {
		$self->_parse_fasta;
	} else {
		die "ERROR: unknown type: ".$self->type." for driver ".$self->driver."\n"; 
	}
}

sub _parse_gff {
	my $self = shift;
	
	die $help if ! exists $O{d};
		
	my %desc;
	open DESC, "$O{d}" or die "$!\n";
	while (<DESC>) {
		my ($desc, $id) = split '\t', $_;
		$desc{$id} = $desc if ! exists $desc{$id};
	}
	close DESC;
	
	
	use Bio::Tools::GFF;
	
	my $in = new Bio::Tools::GFF(-file => $O{i}, -gff_version => 2);
	my $genome = new SeqMiner::Genome;
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
				$gene = new SeqMiner::Genome::Gene;
				$gene->id($id);
				
				my $chr = $feat->seq_id;
				$chr =~ s/(supercont\d\.\d+).+/$1/;
				$gene->chromosome($chr);
				
				$gene->source("broad");
				
				# there is no description yet.
				#$gene->description($feat->get_tag_values("description"));
				#$gene->pseudogene(1) if $gene->description =~ /pseudogene/;
				$gene->description(exists $desc{$id} ? $desc{$id} : "");
				$gene->strand($feat->strand == 1 ? "+" : "-");
				$gene->start($feat->start);
				$gene->end($feat->end);
				
				$genome->add_gene($gene);
			}
			
			my $exon = new SeqMiner::Genome::Exon;
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
}

sub _parse_fasta {
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
}

1;