package varDB::TaxonSet;

use strict;
use warnings;

use varDB::Config;
use varDB::TaxonSet::Taxon;
#use varDB::FamilySet;
use varDB::Family;
use varDB::OrthologSet;
use varDB::ItemSet;
use vars qw( @ISA );
@ISA = ("varDB::ItemSet");

sub new {
	my $class = shift;
	
	my $self = {};
	#$self->{family} = undef;
	bless $self, $class;
    $self->_initialize(@_);
    return $self;
}

sub _initialize {
	my $self = shift;
	my $param = shift;

	my $os = new varDB::OrthologSet;

	open IN, "$VARDB_TAXON_FILE" or die "$!";
	while (<IN>) {
		next if /^[#|\n|taxon_id]/;
		chomp;
		my ($id, $taxon_name, $strain, $ortholog, $family_id, $type, $source, $seed) = split '\t', $_;
		my $taxon = $self->get_item_by_id($id);
		if (! defined $taxon) {
			$taxon = new varDB::TaxonSet::Taxon;
			$taxon->id($id);
			my ($genus, $spp) = ($1, $2) if $taxon_name =~ /(.+)\.(.+)/;
			$taxon->genus($genus);
			$taxon->species($spp);
			$taxon->strain($strain ne "" ? $strain : "_undef_");
			$taxon->type($type);
			$taxon->source($source ne "" ? $source : "_undef_");
			$taxon->seed($seed);
			$self->add($taxon);
		}
		my $family = new varDB::Family;
		$family->id($family_id);
		$family->ortholog($os->get_item_by_id($ortholog));
		$taxon->family->add($family);
	}
	close IN;
}

1;
