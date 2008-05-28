package varDB::Genome;

use varDB::Genome::Chromosome;
use varDB::Genome::Gene;
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
	$self->{ngenes} = 0;
	$self->{organism} = "";
	$self->{strain} = "";
	$self->{chromosome_list} = [];
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
	#push @{ $self->{gene_list_ids} }, $gene->id;
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
	
	foreach my $gene ($self->gene_list) {
		if ($gene->id eq $id) {
			return $gene;
		}
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
	#push @{ $self->{chromosome_list_ids} }, $gene->id;
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
	
	foreach my $chr ($self->chromosome_list) {
		if ($chr->id eq $id) {
			return $chr;
		}
	}
	return undef;
}

sub read_gff {
	my $self = shift;
	my $param = shift;
	
	print STDERR "* reading genome file ... ";
	my $file = $param->{file};
	open IN, "$file" or die "[Genome:read_gff]: cannot read file $file: $!\n";
	while (<IN>) {
		chomp;
		my ($id, $source, $type, $chromosome, $strand, $start, $end, $foo, $description) = split '\t', $_;
		if ($type eq "gene") {
			my $gene = new varDB::Genome::Gene;
			$gene->id($id);
			$gene->source($source);
			$gene->chromosome($chromosome);
			$gene->strand($strand);
			$gene->start($start);
			$gene->end($end);
#			$description = "" if !defined $description;
			my $desc = _parse_description($description);
			$gene->description($desc->{'description'});
			$gene->pseudogene($desc->{'pseudogene'});
			$self->add_gene($gene);
		} elsif ($type eq "exon") {
			my $gene = $self->get_gene_by_id($id);
			my $exon = new varDB::Genome::Exon;
			$exon->id($gene->nexons() + 1);
			$exon->parent($id);
			$exon->strand($strand);
			$exon->start($start);
			$exon->end($end);
			$self->add_exon($exon);
		} # nothing else.
	}
	close IN;
	print STDERR "OK\n";
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
			print $fh ">", 	$chr->id, "\n";
			print $fh _format_seq($chr->seq), "\n";
		}
	} else {
		foreach my $gene ($self->gene_list) {
			if ($type eq "nucleotide") {
				print $fh ">", $gene->id, " description:", $gene->description, "\n";
				print $fh _format_seq($gene->seq), "\n";
			} elsif ($type eq "translation" or $type eq "protein") {
				if (defined $gene->translation) {
					print $fh ">", $gene->id, " description:", $gene->description, "\n";
					print $fh _format_seq($gene->translation), "\n";
				}
			}
		}
	}
}

sub _format_seq {
	my $seq = shift;
	$seq =~ s/(.{60})/$1\n/g;
	return $seq;
}

1;
