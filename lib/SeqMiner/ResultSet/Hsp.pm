package SeqMiner::ResultSet::Hsp;

use strict;
use warnings;

sub new {
	my $class = shift;
	
	my $self = {};
	$self->{start} = undef;
	$self->{end} = undef;
	$self->{evalue} = undef;
	$self->{score} = undef;

	bless $self, $class;
    $self->_initialize(@_) if @_;
    return $self;
}

sub _initialize {
	my $self = shift;
	my $param = shift;
	
	$self->{start} = $param->{start} if defined $param->{start};
	$self->{end} = $param->{end} if defined $param->{end};
	$self->{score} = $param->{score} if defined $param->{score};
	$self->{evalue} = $param->{evalue} if defined $param->{evalue};
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

sub score {
	my $self = shift;
	$self->{score} = shift if @_;
	return $self->{score};
}

sub evalue {
	my $self = shift;
	$self->{evalue} = shift if @_;
	return $self->{evalue};
}

1;