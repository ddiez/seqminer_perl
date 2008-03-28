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
	$self->{genes} = {};
	$self->{gene_list} = [];
	$self->{ngenes} = 0;
}

sub get_ngenes {
	return shift->{ngenes};
}

sub add_gene {
	my $self = shift;
	my $gene = new varDB::Gene(@_);
	$self->{ngenes}++;
	$self->{genes}->{$gene->get_id} = $gene;
	push @{ $self->{gene_list} }, $gene->get_id;
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
	my $gene = $self->get_gene($exon->get_parent);
	$gene->add_exon($exon);
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
	
	foreach my $id (@{ $self->{gene_list} }) {
		my $gene = $self->get_gene($id);
		print
			"$id\tgene\t",
			$gene->get_chromosome, "\t",
			$gene->get_strand, "\t",
			$gene->get_start, "\t",
			$gene->get_end, "\t",
			"-\t",
			$gene->get_description, "\n";
		my $nexons = $gene->get_nexons;
		foreach my $n (1 .. $nexons) {
		my $exon = $gene->get_exon($n);
		print 
			"$id\texon\t",
			"-\t",
			$exon->get_strand, "\t",
			$exon->get_start, "\t",
			$exon->get_end, "\t",
			"$n\t-\n",
		}
	}
}

1;