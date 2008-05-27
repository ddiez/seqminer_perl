package varDB::TaxonSet;

use strict;
use warnings;

use varDB::Config;
use varDB::TaxonSet::Taxon;

sub new {
	my $class = shift;
	
	my $self = {};
	$self->{taxon_list} = [];
	$self->{ntaxons} = 0;
	bless $self, $class;
    $self->_initialize(@_);
    return $self;
}

sub _initialize {
	my $self = shift;
	my $param = shift;
	
	open IN, "$VARDB_ORGANISM_FILE" or die "$!";
	while (<IN>) {
		next if /^[#|\n]/;
		chomp;
		my ($taxonid, $genus, $spp, $strain) = split '\t', $_;
		my $taxon = new varDB::TaxonSet::Taxon;
		$taxon->id($taxonid);
		$taxon->genus($genus);
		$taxon->species($spp);
		$taxon->strain($strain);
		$self->add_taxon($taxon);
	}
	close IN;
}

sub length {
	return shift->{ntaxons};
}

sub taxon_list {
	my $self = shift;
	return @{ $self->{taxon_list} };
}

sub add_taxon {
	my $self = shift;
	push @{ $self->{taxon_list} }, shift;
	$self->{ntaxons}++;
}

sub get_taxon_by_pos {
	my $self = shift;
	my $n = shift;
	return $self->{taxon_list}->[$n];
}

sub get_taxon_by_id {
	my $self = shift;
	my $id = shift;
	foreach my $taxon ($self->taxon_list) {
		return $taxon if $taxon->id eq $id;
	}
	return undef;
}

1;
