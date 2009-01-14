package SeqMiner::Genome;

use SeqMiner::Genome::Chromosome;
use SeqMiner::Genome::Gene;
use strict;
use warnings;

sub new {
	my $class = shift;
	
	my $self = {};
	bless $self, $class;
    $self->_initialize(@_);
    return $self;
}

sub _initialize {
	my $self = shift;
	my $param = shift;
	$self->{genes} = {};
	$self->{gene_list} = [];
	$self->{genes} = {};
	$self->{ngenes} = 0;
	$self->{organism} = "";
	$self->{strain} = "";
	$self->{chromosome_list} = [];
	$self->{chrs} = {};
	$self->{nchromosomes} = 0;
	$self->read_gff($param) if defined $param->{file};
}

sub debug {
	my $self = shift;
	print STDERR <<"DEBUG";

organism: $self->{organism}
ngenes: $self->{ngenes}
	
DEBUG
}

sub organism {
	my $self = shift;
	$self->{organism} = shift if @_;
	return $self->{organism};
}

sub strain {
	my $self = shift;
	$self->{strain} = shift if @_;
	return $self->{strain};
}

sub ngenes {
	return shift->{ngenes};
}

sub length {
	return shift->{ngenes};
}

sub gene_list {
	return @{ shift->{gene_list} };
}

sub add_gene {
	my $self = shift;
	my $gene = shift;
	push @{ $self->{gene_list} }, $gene;
	$self->{genes}->{$gene->id} = $gene;
	$self->{ngenes}++;
}

sub get_gene {
	my $self = shift;
	my $n = shift;
	return $self->{gene_list}->[$n];
}

sub get_gene_by_id {
	my $self = shift;
	my $id = shift;
	if (exists $self->{genes}->{$id}) {
		return $self->{genes}->{$id};
	}
	return undef;
}

sub add_exon {
	my $self = shift;
	my $exon = shift;
	my $gene = $self->get_gene_by_id($exon->parent);
	$gene->add_exon($exon);
}

sub chromosome_list {
	return @{ shift->{chromosome_list} };
}

sub add_chromosome {
	my $self = shift;
	my $chr = shift;
	push @{ $self->{chromosome_list} }, $chr;
	$self->{chrs}->{$chr->id} = $chr;
	$self->{nchromosomes}++;
}

sub get_chromosome {
	my $self = shift;
	my $n = shift;
	return $self->{chromosome_list}->[$n];
}

sub get_chromosome_by_id {
	my $self = shift;
	my $id = shift;
	if (exists $self->{chrs}->{$id}) {
		return $self->{chrs}->{$id};
	}
	return undef;
}

sub read_gff {
	my $self = shift;
	my $param = shift;
	
	#print STDERR "* reading genome file ... ";
	my $file = $param->{file};
	open IN, "$file" or die "[Genome:read_gff]: cannot read file $file: $!\n";
	while (<IN>) {
		chomp;
		my ($id, $source, $type, $chromosome, $strand, $start, $end, $foo, $description) = split '\t', $_;
		if ($type eq "gene") {
			my $gene = new SeqMiner::Genome::Gene;
			$gene->id($id);
			$gene->source($source);
			$gene->chromosome($chromosome);
			$gene->strand($strand);
			$gene->start($start);
			$gene->end($end);
			my $desc = _parse_description($description);
			$gene->description(defined $desc->{'description'} ? $desc->{'description'} : "");
			$gene->pseudogene($desc->{'pseudogene'});
			$self->add_gene($gene);
		} elsif ($type eq "exon") {
			my $gene = $self->get_gene_by_id($id);
			my $exon = new SeqMiner::Genome::Exon;
			$exon->id($gene->nexons() + 1);
			$exon->parent($id);
			$exon->strand($strand);
			$exon->start($start);
			$exon->end($end);
			$self->add_exon($exon);
		} # nothing else.
	}
	close IN;
	#print STDERR "OK\n";
}

sub _parse_description {
	my $desc = shift;
	my @fields = split ';', $desc;
	my %desc;
	foreach my $field (@fields) {
		my @tmp = split '=', $field;
		$desc{$tmp[0]} = $tmp[1];
	}
	return \%desc;
}

# format:
# id
# type
# chromosome
# strand
# start
# end
# exon number
# description
sub print_gff {
	my $self = shift;
	my $param = shift;
	
	my $fh = *STDOUT;
	if ($param->{file}) {
		open OUT, ">$param->{file}" or die "cannot open $param->{file} for writing: $!\n";
		$fh = *OUT;
	}
	
	foreach my $gene ($self->gene_list) {
		my $desc = $gene->get_gff_desc;
		print $fh
			$gene->id, "\t",
			$gene->source, "\t",
			"gene\t",
			$gene->chromosome, "\t",
			$gene->strand, "\t",
			$gene->start, "\t",
			$gene->end, "\t",
			"-\t",
			$desc, "\n";
		my $nexons = $gene->nexons;
		foreach my $exon ($gene->exon_list) {
			print $fh 
				$gene->id, "\t",
				$gene->source, "\t",
				"exon\t",
				"-", "\t",
				$exon->strand, "\t",
				$exon->start, "\t",
				$exon->end, "\t",
				$exon->id, "\t",
				"-", "\n";
		}	
	}
	close $fh;
}

sub print_fasta {
	my $self = shift;
	my $param = shift;
	
	my $fh = *STDOUT;
	if ($param->{file}) {
		open OUT, ">$param->{file}" or die "cannot open $param->{file} for writing: $!\n";
		$fh = *OUT;
	}
	
	my $type = $param->{type};
	
	if ($type eq "genome") {
		foreach my $chr ($self->chromosome_list) {
			print $fh ">", $chr->id, defined $chr->description ? " chromosome: ".$chr->description.";\n" : "\n";
			print $fh _format_seq($chr->seq);
		}
	} else {
		foreach my $gene ($self->gene_list) {
			my $seq;
			if ($type eq "nucleotide") {
				$seq = $gene->seq;
			} elsif ($type eq "translation" or $type eq "protein") {
				$seq = $gene->translation;
			}
			if (defined $seq) {
				print $fh ">", $gene->id, " ", $gene->description, "\n";
				print $fh _format_seq($seq);
			}
		}
	}
}

sub _format_seq {
	my $seq = shift;
	my $seqn = CORE::length $seq;
	$seq =~ s/(.{60})/$1\n/g;
	$seq .= "\n" if $seqn % 60 != 0;
	return $seq;
}

1;
