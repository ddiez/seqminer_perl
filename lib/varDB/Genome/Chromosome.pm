package varDB::Genome::Chromosome;

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
	$self->{seq} = undef;
}

sub id {
	my $self = shift;
	$self->{id} = shift if @_;
	return $self->{id};
}

sub seq {
	my $self = shift;
	$self->{seq} = shift if @_;
	return $self->{seq};
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

sub description {
	my $self = shift;
	$self->{description} = shift if @_;
	return $self->{description};
}

1;