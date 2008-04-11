package varDB::Search::ResultSet;

use strict;
use warnings;

use varDB::Search::Result;

sub new {
	my $class = shift;
	
	my $self = {};
	$self->{name} = undef;
	$self->{nres} = 0;
	$self->{res_list} = [];
	
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
	return shift->{nres};
}

sub name {
	my $self = shift;
	$self->{name} = shift if @_;
	return $self->{name};
}

sub res_list {
	return @{ shift->{res_list} };
}

sub add_result {
	my $self = shift;
	my $res = shift;
	push @{$self->{res_list}}, $res;
	$self->{nres}++;
}

sub get_res {
	my $self = shift;
	my $n = shift;
	return undef if $n > $self->length;
	return $self->{res_list}->[$n];
}

1;