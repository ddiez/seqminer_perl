package varDB::Genome;

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
	push @{ $self->{gene_list_ids} }, $gene->id;
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

sub read_gff {
	my $self = shift;
	my $param = shift;
	
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
			$gene->description($description);
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
	
	foreach my $gene ($self->gene_list) {
		print
			$gene->id, "\t",
			$gene->source, "\t",
			"gene\t",
			$gene->chromosome, "\t",
			$gene->strand, "\t",
			$gene->start, "\t",
			$gene->end, "\t",
			"-\t",
			$gene->description, "\n";
		my $nexons = $gene->nexons;
		foreach my $exon ($gene->exon_list) {
			print 
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
}

1;
