package varDB::Genome;

use varDB::Gene;
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

sub add_gene {
	my $self = shift;
	my $gene = new varDB::Gene(@_);
	$self->{ngenes}++;
	$self->{genes}->{$gene->id} = $gene;
	push @{ $self->{gene_list} }, $gene->id;
}

sub get_gene_list {
	return @{ shift->{gene_list} };
}

sub get_gene {
	my $self = shift;
	my $id = shift;
	return $self->{genes}->{$id};
}

sub add_exon {
	my $self = shift;
	my $exon = shift;
	my $gene = $self->get_gene($exon->parent);
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
			my $gene = new varDB::Gene;
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
			my $gene = $self->get_gene($id);
			my $exon = new varDB::Exon;
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
	
	foreach my $id (@{ $self->gene_list }) {
		my $gene = $self->get_gene($id);
		print
			"$id\t",
			$gene->source, "\t",
			"gene\t",
			$gene->chromosome, "\t",
			$gene->strand, "\t",
			$gene->start, "\t",
			$gene->end, "\t",
			"-\t",
			$gene->description, "\n";
		my $nexons = $gene->nexons;
		foreach my $n (1 .. $nexons) {
		my $exon = $gene->get_exon($n);
		print 
			"$id\t",
			$gene->source, "\t",
			"exon\t",
			"-\t",
			$exon->strand, "\t",
			$exon->start, "\t",
			$exon->end, "\t",
			"$n\t-\n",
		}
	}
}

1;
