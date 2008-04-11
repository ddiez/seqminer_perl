package varDB::ResultSet::Hsp;

use strict;
use warnings;

sub new {
	my $class = shift;
	
	my $self = {};
	$self->{start} = undef;
	$self->{end} = undef;

	bless $self, $class;
    $self->_initialize(@_) if @_;
    return $self;
}

sub _initialize {
	my $self = shift;
	my $param = shift;
	
	$self->{start} = $param->{start} if defined $param->{start};
	$self->{end} = $param->{end} if defined $param->{end};
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

1;