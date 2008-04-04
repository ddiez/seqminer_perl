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

sub id {
	my $self = shift;
	$self->{id} = shift if @_;
	return $self->{id};
}

sub start {
	my $self = shift;
	$self->{start} = shift if @_;
	return $self->{start};
}


sub end {
	my $self = shift;
	$self->{end} = shift if @_;
	return $self->{end};
}

sub strand {
	my $self = shift;
	$self->{strand} = shift if @_;
	return $self->{strand};
}

sub parent {
	my $self = shift;
	$self->{parent} = shift if @_;
	return $self->{parent};
}

1;
