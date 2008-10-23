package varDB::TaxonSet;

use strict;
use warnings;

use varDB::Config;
use varDB::TaxonSet::Taxon;
use varDB::FamilySet;
use varDB::Family;
use varDB::Ortholog;
use varDB::ItemSet;
use vars qw( @ISA );
@ISA = ("varDB::ItemSet");

sub new {
	my $class = shift;
	
	my $self = {};
	$self->{family} = undef;
	bless $self, $class;
    $self->_initialize(@_);
    return $self;
}

sub _initialize {
	my $self = shift;
	my $param = shift;

	my $os = new varDB::Ortholog;

	open IN, "$VARDB_TAXON_FILE" or die "$!";
	while (<IN>) {
		next if /^[#|\n|taxon_id]/;
		chomp;
		my ($id, $taxon_name, $strain, $ortholog, $family_id, $search_type) = split '\t', $_;
		my $taxon = $self->get_taxon_by_id($id);
		if (! defined $taxon) {
			$taxon = new varDB::TaxonSet::Taxon;
			$taxon->id($id);
			my ($genus, $spp) = ($1, $2) if $taxon_name =~ /(.+)\.(.+)/;
			$taxon->genus($genus);
			$taxon->species($spp);
			$taxon->strain($strain) if $strain ne "";
			$taxon->search_type($search_type);
			my $fs = new varDB::FamilySet;
			$taxon->family($fs);
			$self->add($taxon);
		}
		my $fs = $taxon->family;
		my $family = new varDB::Family;
		$family->id($family_id);
		$family->hmm($os->hmm($ortholog));
		$fs->add($family);
	}
	close IN;
}

sub taxon_list {
	return shift->SUPER::item_list;
}

sub get_taxon_by_pos {
	return shift->SUPER::get_item_by_pos(@_);
}

sub get_taxon_by_id {
	return shift->SUPER::get_item_by_id(@_);
}

1;
