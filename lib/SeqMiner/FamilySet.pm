package SeqMiner::FamilySet;

use strict;
use warnings;
use SeqMiner::Config;
use SeqMiner::Family;
use SeqMiner::ItemSet;
use vars qw( @ISA );
@ISA = ("SeqMiner::ItemSet");

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

1;