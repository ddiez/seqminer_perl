package varDB::ResultSet::Result;

use strict;
use warnings;

use varDB::ResultSet::Hit;

sub new {
	my $class = shift;
	
	my $self = {};
	$self->{name} = undef;
	$self->{nhit} = 0;
	$self->{hit_list} = [];
	$self->{current} = 0;
	
	bless $self, $class;
    $self->_initialize(@_) if @_;
    return $self;
}

sub _initialize {
	my $self = shift;
	my $param = shift;
	# NOTE: nothing here yet.
}

sub length {
	return shift->{nhit};
}

sub name {
	my $self = shift;
	$self->{name} = shift if @_;
	return $self->{name};
}

sub hit_list {
	return @{ shift->{hit_list} };
}

sub next_hit {
	my $self = shift;
	return $self->{hit_list}->[$self->{current}++];
}

sub rewind {
	my $self = shift;
	$self->{current} = 0;
}


sub add_hit {
	my $self = shift;
	my $hit = shift;
	push @{$self->{hit_list}}, $hit;
	$self->{nhit}++;
}

sub get_hit {
	my $self = shift;
	my $n = shift;
	return undef if $n > $self->length;
	return $self->{hit_list}->[$n];
}

1;