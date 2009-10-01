package SeqMiner::TaxonSet::Taxon;

=head1 MAIN

SeqMiner::TaxonSet::Taxon

Methods working at taxon level allowing various task to be performed. Mainly is used for
maintaining taxon information.

=cut

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

	$self->{genus} = undef;
	$self->{species} = undef
	$self->{strain} = undef;
	$self->{type} = undef;
	$self->{source} = undef;
}

sub name {
	my $self = shift;
	$self->organism;
}

sub binomial {
	my $self = shift;
	$self->genus =~ /^(.{1})/;
	return $1.".".$self->species;
}

sub binomial_long {
	my $self = shift;
	return $self->genus.".".$self->species;
}

sub organism {
	my $self = shift;

	if ($self->strain ne "_undef_") {
		return $self->genus.".".$self->species."_".$self->strain;
	} else {
		return $self->genus.".".$self->species;
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

sub source {
	my $self = shift;
	$self->{source} = shift if @_;
	return $self->{source};
}

sub debug {
	my $self = shift;
	print STDERR "* taxon: ", $self->id, "\n";
	print STDERR "* organism: ", $self->organism, "\n";
	print STDERR "* genus: ", $self->genus, "\n";
	print STDERR "* species: ", $self->species, "\n";
	print STDERR "* strain: ", $self->strain, "\n";
	print STDERR "* type: ", $self->type, "\n";
	print STDERR "* source: ", $self->source, "\n\n";
}

1;
