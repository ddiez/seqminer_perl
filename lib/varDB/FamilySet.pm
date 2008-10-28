package varDB::FamilySet;

use strict;
use warnings;
use varDB::Config;
use varDB::Family;
use varDB::ItemSet;
use vars qw( @ISA );
@ISA = ("varDB::ItemSet");

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