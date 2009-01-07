package SeqMiner::Ortholog;

use strict;
use warnings;
use SeqMiner::Config;
use SeqMiner::ItemSet::Item;
use vars qw( @ISA );
@ISA = ("SeqMiner::ItemSet::Item");

sub new {
	my $class = shift;
	
	my $self = {};
	bless $self, $class;
    $self->_initialize(@_);
    return $self;
}

sub _initialize {
	my $self = shift;
}

sub hmm {
	my $self = shift;
	$self->{hmm} = shift if @_;
	return $self->{hmm};
}

1;
