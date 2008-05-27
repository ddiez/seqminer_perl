package varDB::TaxonSet::Taxon;

use strict;
use warnings;

sub new {
	my $class = shift;
	
	my $self = {};
	bless $self, $class;
    $self->_initialize(@_);
    return $self;
}

sub _initialize {
	my $self = shift;
	$self->{taxonid} = undef;
	$self->{genus} = undef;
	$self->{species} = undef
	$self->{strain} = undef;
}

sub id {
	my $self = shift;
	$self->{taxonid} = shift if @_;
	return $self->{taxonid};
}

sub binomial {
	my $self = shift;
	$self->genus =~ /^(.{1})/;
	return $1.".".$self->species;
}

sub organism {
	my $self = shift;
	return $self->genus.".".$self->species;
}

sub organism_dir {
	my $self = shift;
	return $self->binomial."_".$self->strain;
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

1;