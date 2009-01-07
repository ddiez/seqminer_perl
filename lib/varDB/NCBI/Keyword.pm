package SeqMiner::NCBI::Keyword;

use strict;
use warnings;
use SeqMiner::Config;

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