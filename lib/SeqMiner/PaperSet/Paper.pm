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
	$self->{ortholog} = new SeqMiner::ItemSet;
	bless $self, $class;
    $self->_initialize(@_);
    return $self;
}

sub _initialize {
	my $self = shift;
}

sub ortholog {
	my $self = shift;
	$self->{ortholog} = shift if @_;
	return $self->{ortholog};
}

sub name {
	my $self = shift;

#	if ($self->strain ne "_undef_") {
#		return $self->genus.".".$self->species."_".$self->strain;
#	} else {
#		return $self->genus.".".$self->species;
#	} 
	return $self->id;
}

1;