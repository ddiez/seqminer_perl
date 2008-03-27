package varDB::Exon;

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
	$self->{parent} = $param->{parent};	
	$self->{start} = $param->{start};
	$self->{end} = $param->{end};
	$self->{strand} = $param->{strand};
}

sub get_id {
	return shift->{id};
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

sub get_parent {
	return shift->{parent};
}

1;
