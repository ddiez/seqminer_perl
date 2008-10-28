package varDB::TaxonSet::Taxon;

use strict;
use warnings;
use varDB::FamilySet;
#use varDB::SearchSet;
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

	$self->{genus} = undef;
	$self->{species} = undef
	$self->{strain} = undef;
	$self->{family} = new varDB::FamilySet;
	$self->{type} = undef;
}

sub name {
	my $self = shift;
	if (defined $self->strain) {
		return $self->genus.".".$self->species."_".$self->strain;
	} else {
		return $self->genus.".".$self->species;
	}
}

sub binomial {
	my $self = shift;
	$self->genus =~ /^(.{1})/;
	return $1.".".$self->species;
}

sub organism {
	my $self = shift;
	my $org = $self->genus.".".$self->species;
	$org .= "_".$self->strain if defined $self->strain;
	return $org;
}

sub dir {
	my $self = shift;
	if (defined $self->strain) {
		return $self->binomial."_".$self->strain;
	} else {
		return $self->binomial;
	}
}

sub key {
	my $self = shift;
	my $key = $1 if $self->genus =~ /^(.{1})/;
	$key .= $1 if $self->species =~ /^(.{2})/;
	return $key."_".$self->strain;
}

sub genus {
	my $self = shift;
	$self->{genus} = shift if @_;
	return $self->{genus};
}

sub species {
	my $self = shift;
	$self->{species} = shift if @_;
	return $self->{species};
}

sub strain {
	my $self = shift;
	$self->{strain} = shift if @_;
	return $self->{strain};
}

sub type {
	my $self = shift;
	$self->{type} = shift if @_;
	return $self->{type};
}

sub family {
	#my $self = shift;
	#$self->{family}->add(@_) if @_;
	return shift->{family};
}

1;