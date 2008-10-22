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
	$self->{search_type} = undef;
}

sub id {
	my $self = shift;
	$self->{taxonid} = shift if @_;
	return $self->{taxonid};
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
	if ($self->strain ne "") {
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

sub search_type {
	my $self = shift;
	$self->{search_type} = shift if @_;
	return $self->{search_type};
}

sub get_family_by_pos {
	my $self = shift;
	my $n = shift;
	return $self->{family_list}->[$n];
}

sub get_family_by_id {
	my $self = shift;
	my $id = shift;
	foreach my $family ($self->family_list) {
		return $family if $family->id eq $id;
	}
	return undef;
}

sub get_taxon_by_id {
	my $self = shift;
	my $id = shift;
	foreach my $taxon ($self->taxon_list) {
		return $taxon if $taxon->id eq $id;
	}
	return undef;
}

sub family_list {
	return @{ shift->{family_list}};
}

sub add_family {
	my $self = shift;
	use varDB::Family;
	my $family = new varDB::Family;
	$family->name(shift);
	$family->ortholog(shift);
	$family->hmm(shift);
	#$family->taxonid(shift);
	push @{$self->{family_list}}, $family;
}

sub search {
	my $self = shift;
	
	if ($self->{search_type} eq "isolate") {
		$self->_search_isolate;
	} else {
		$self->_search_genome;
	}
}

sub _search_isolate {
	my $self = shift;
	use varDB::Search;
	
	foreach my $family ($self->family_list) {
		my $search = new varDB::Search($self->search_type);
		$search->family($family);
		$search->taxon($self);
		if ($search->execute == 0) {
			print STDERR "[ERROR] isolate search failed for family: ", $family->name, "\n";
		}
	}
}

sub _search_genome {
	my $self = shift;
	use varDB::Search;
	
	foreach my $family ($self->family_list) {
		my $search = new varDB::Search($self->search_type);
		$search->family($family);
		$search->taxon($self);
		if ($search->execute == 0) {
			print STDERR "[ERROR] genome search failed for family: ", $family->name, "\n";
		}
	}
}

1;