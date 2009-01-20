package SeqMiner::PaperSet::Paper;

=head1 MAIN

SeqMiner::PaperSet::Paper;

=cut


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

1;