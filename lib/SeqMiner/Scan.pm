package SeqMiner::Scan;

use strict;
use warnings;

use SeqMiner::ItemSet::Item;
use base "SeqMiner::ItemSet::Item";

sub new {
	my $class = shift;
	my $self = $class->SUPER::new(@_);
	bless $self, $class;
    $self->_initialize(@_);
    return $self;
}

sub _initialize {
	my $self = shift;
}

1;