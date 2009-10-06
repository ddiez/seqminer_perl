package SeqMiner::Family;

use strict;
use warnings;
use SeqMiner::ItemSet::Item;
use base "SeqMiner::ItemSet::Item";

sub new {
	my $class = shift;
	my $self = $class->SUPER::new();
	bless $self, $class;
	$self->_initialize(@_);
	return $self;
}

sub _initialize {
	my $self = shift;
	$self->{name} = undef;
	$self->{taxon} = undef;
	$self->{ortholog} = undef;
}

sub name {
	my $self = shift;
	$self->{name} = shift if @_;
	return $self->{name};
}

sub ortholog {
	my $self = shift;
	$self->{ortholog} = shift if @_;
	return $self->{ortholog};
}

sub taxon {
	my $self = shift;
	$self->{taxon} = shift if @_;
	return $self->{taxon};
}

#sub type {
#	my $self = shift;
#	$self->{type} = shift if @_;
#	return $self->{type};
#}

1;