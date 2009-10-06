package SeqMiner::TaxonSet;

use strict;
use warnings;

use SeqMiner::Config;
#use SeqMiner::FamilySet;
#use SeqMiner::Family;
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
	
	if (defined $param->{empty}) {
		return if $param->{empty} == 1;
	}
	
	require SeqMiner::OrthologSet;
	my $os = new SeqMiner::OrthologSet;

	open IN, "$SM_TAXON_FILE" or die "$!";
	while (<IN>) {
		next if /^[#|\n|taxon_id]/;
		chomp;

		my ($id, $genus, $spp, $strain, $type, $source) = split '\t', $_;
		require SeqMiner::TaxonSet::Taxon;
		my $taxon = new SeqMiner::TaxonSet::Taxon;
		$taxon->id($id);
		$taxon->genus($genus);
		$taxon->species($spp);
		$taxon->strain($strain ne "" ? $strain : "_undef_");
		$taxon->type($type);
		$taxon->source($source ne "" ? $source : "_undef_");
		#$taxon->seed($seed);
		#$taxon->ortholog(new SeqMiner::ItemSet);
		#$taxon->ortholog->add($os->get_item_by_id($ortholog));
		#$taxon->family($family_id);
		$self->add($taxon);

#		my ($id, $taxon_name, $strain, $ortholog, $family_id, $type, $source, $seed) = split '\t', $_;
#		my $taxon = $self->get_item_by_id($id);
#		if (! defined $taxon) {
#			$taxon = new SeqMiner::TaxonSet::Taxon;
#			$taxon->id($id);
#			my ($genus, $spp) = ($1, $2) if $taxon_name =~ /(.+)\.(.+)/;
#			$taxon->genus($genus);
#			$taxon->species($spp);
#			$taxon->strain($strain ne "" ? $strain : "_undef_");
#			$taxon->type($type);
#			$taxon->source($source ne "" ? $source : "_undef_");
#			$taxon->seed($seed);
#			#$taxon->ortholog(new SeqMiner::ItemSet);
#			#$taxon->ortholog->add($os->get_item_by_id($ortholog));
#			#$taxon->family($family_id);
#			$self->add($taxon);
#		}
		# old way (deprecated module FamilySet)
#		my $family = new SeqMiner::Family;
#		$family->id($family_id);
#		$family->ortholog($os->get_item_by_id($ortholog));
#		$taxon->family->add($family);

		# new way (like in PaperSet)
		#$taxon->family($family_id);
		#$taxon->ortholog->add($os->get_item_by_id($ortholog));
	}
	close IN;
}

sub filter_by_taxon_name {
	my $self = shift;
	my $filter = shift;
	return $self if $#{$filter} == -1;
	my $ts = new SeqMiner::TaxonSet({empty => 1});
	for my $taxon ($self->item_list) {
		for my $f (@{$filter}) {
			if ($taxon->name =~ /$f/) {
				$ts->add($taxon);
				last;
			}
		}
	}
	return $ts;
}

sub filter_by_taxon_type {
	my $self = shift;
	my $filter = shift;
	return $self if $#{$filter} == -1;
	my $ts = new SeqMiner::TaxonSet({empty => 1});
	for my $taxon ($self->item_list) {
		for my $f (@{$filter}) {
			if ($taxon->type =~ /$f/) {
				$ts->add($taxon);
				last;
			}
		}
	}
	return $ts;
}

sub debug {
	my $self = shift;
	print STDERR "#---", ref $self, "--->\n";
	print STDERR "* number of taxons: ", $self->length, "\n";
	for my $t ($self->item_list) {
		print STDERR "* ", $t->name, " [", $t->type, "]\n";
	}
	print STDERR "\\\\\n";
}

1;
