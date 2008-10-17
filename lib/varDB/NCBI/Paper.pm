package varDB::NCBI::Paper;

use strict;
use warnings;
use varDB::Config;

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