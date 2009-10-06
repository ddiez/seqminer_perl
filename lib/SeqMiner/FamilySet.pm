package SeqMiner::FamilySet;

use strict;
use warnings;
use SeqMiner::Config;
use SeqMiner::ItemSet;
use base "SeqMiner::ItemSet";

sub new {
	my $class = shift;
	my $self = $class->SUPER::new(@_);
	bless $self, $class;
    $self->_initialize(@_);
    return $self;
}

sub _initialize {
	my $self = shift;
	my $param = shift;

	require SeqMiner::Family;

	if (defined $param->{empty}) {
		return if $param->{empty} == 1;
	}
	
	open IN, "$SM_FAMILY_FILE" or die "$!";
	while (<IN>) {
		next if /^[#|\n]/;
		chomp;
		my ($taxon, $ortholog, $name) = split '\t', $_;
		my $id = "$taxon.$ortholog";
		my $family = new SeqMiner::Family;
		$family->id($id);
		$family->name($name);
		$family->taxon($taxon);
		$family->ortholog($ortholog);
		$self->add($family);
	}
	close IN;
}

sub filter_by_ortholog_name {
	my $self = shift;
	my $filter = shift;
	return $self if $#{$filter} == -1;
	my $fs = new SeqMiner::FamilySet({empty => 1});
	for my $family ($self->item_list) {
		for my $f (@{$filter}) {
			if ($family->ortholog =~ /$f/) {
				$fs->add($family);
				last;
			}
		}
	}
	return $fs;
}

sub get_family_name {
	my $self = shift;
	my $taxon = shift;
	my $ortholog = shift;
	
	for my $f ($self->item_list) {
		if ($f->taxon eq $taxon and $f->ortholog eq $ortholog) {
			return $f->name;
		}
	}
	
	# if not, return the generic name of the ortholog group.
	require SeqMiner::OrthologSet;
	my $os = new SeqMiner::OrthologSet;
	my $o = $os->get_item_by_id($ortholog);
	return $o->name;
}

sub get_taxon_array {
	my $self = shift;
	my @t;
	for my $f ($self->item_list) {
		push @t, $f->taxon;
	}
	return @t;
}

sub get_ortholog_array {
	my $self = shift;
	my @t;
	for my $f ($self->item_list) {
		push @t, $f->ortholog;
	}
	return @t;
}

sub debug {
	my $self = shift;
	print STDERR "#---", ref $self, "--->\n";
	print STDERR "* number of families: ", $self->length, "\n";
	for my $f ($self->item_list) {
		print STDERR "* ", $f->id, "\t", $f->ortholog, "\t", $f->name, "\n";
	}
	print STDERR "\\\\\n";
}

1;