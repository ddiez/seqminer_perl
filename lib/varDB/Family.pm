package varDB::Family;

use strict;
use warnings;
use varDB::ItemSet::Item;
use vars qw( @ISA );
@ISA = ("varDB::ItemSet::Item");

sub new {
	my $class = shift;
	
	my $self = {};
	bless $self, $class;
    $self->_initialize(@_);
    return $self;
}

sub _initialize {
	my $self = shift;
	$self->{name} = undef;
	$self->{ortholog} = undef;
}

# an alias to id.
sub name {
	shift->id(@_);
}

sub ortholog {
	my $self = shift;
	$self->{ortholog} = shift if @_;
	return $self->{ortholog};
}

sub hmm {
	my $self = shift;
	$self->{hmm} = shift if @_;
	return $self->{hmm};
}

1;