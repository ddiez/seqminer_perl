package varDB::ItemSet::Item;

use strict;
use warnings;

sub new {
	my $class = shift;
	
	my $self = {};
	$self->{id} = undef;
	bless $self, $class;
    $self->_initialize(@_);
    return $self;
}

sub _initialize {
	my $self = shift;
	my $param = shift;
}

sub id {
	my $self = shift;
	$self->{id} = shift if @_;
	return $self->{id};
}

1;