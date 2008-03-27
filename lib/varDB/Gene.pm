package varDB::Gene;

use varDB::Exon;
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
	$self->{id} = $param->{id};
	$self->{name} = $param->{name};
	$self->{description} = $param->{description};
	$self->{chromosome} = $param->{chromosome};
	$self->{start} = $param->{start};
	$self->{end} = $param->{end};
	$self->{strand} = $param->{strand};
	$self->{exons} = {};
	$self->{exon_list} = [];
	$self->{nexons} = 0;
}

sub get_id {
	return shift->{id};
}

sub get_name {
	return shift->{name};
}

sub get_description {
	return shift->{description};
}

sub get_chromosome {
	return shift->{chromosome};
}

sub set_chromosome {
	my $self = shift;
	$self->{chromosome} = shift;
}

sub get_start {
	return shift->{start};
}

sub set_start {
	my $self = shift;
	$self->{start} = shift;
}

sub get_end {
	return shift->{end};
}

sub set_end {
	my $self = shift;
	$self->{end} = shift;
}

sub get_strand {
	return shift->{strand};
}

sub set_strand {
	my $self = shift;
	$self->{strand} = shift;
}

sub get_nexons {
	return shift->{nexons};
}

sub get_exon {
	my $self = shift;
	my $id = shift;
	return $self->{exons}->{$id};
}


sub add_exon {
	my $self = shift;
	my $exon = new varDB::Exon(@_);
	$self->{nexons}++;
	$self->{exons}->{$exon->get_id} = $exon;
	push @{ $self->{exon_list} }, $exon->get_id;
}

sub get_exon_list {
	return shift->{exon_list};
}

1;
