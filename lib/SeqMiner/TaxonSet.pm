package SeqMiner::TaxonSet;

use strict;
use warnings;

use SeqMiner::Config;
use SeqMiner::TaxonSet::Taxon;
#use SeqMiner::FamilySet;
use SeqMiner::Family;
use SeqMiner::OrthologSet;
use SeqMiner::ItemSet;
use vars qw( @ISA );
@ISA = ("SeqMiner::ItemSet");

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

	my $os = new SeqMiner::OrthologSet;

	open IN, "$SM_TAXON_FILE" or die "$!";
	while (<IN>) {
		next if /^[#|\n|taxon_id]/;
		chomp;
		my ($id, $taxon_name, $strain, $ortholog, $family_id, $type, $source, $seed) = split '\t', $_;
		my $taxon = $self->get_item_by_id($id);
		if (! defined $taxon) {
			$taxon = new SeqMiner::TaxonSet::Taxon;
			$taxon->id($id);
			my ($genus, $spp) = ($1, $2) if $taxon_name =~ /(.+)\.(.+)/;
			$taxon->genus($genus);
			$taxon->species($spp);
			$taxon->strain($strain ne "" ? $strain : "_undef_");
			$taxon->type($type);
			$taxon->source($source ne "" ? $source : "_undef_");
			$taxon->seed($seed);
			#$taxon->ortholog(new SeqMiner::ItemSet);
			#$taxon->ortholog->add($os->get_item_by_id($ortholog));
			#$taxon->family($family_id);
			$self->add($taxon);
		}
		# old way (deprecated module FamilySet)
#		my $family = new SeqMiner::Family;
#		$family->id($family_id);
#		$family->ortholog($os->get_item_by_id($ortholog));
#		$taxon->family->add($family);

		# new way (like in PaperSet)
		$taxon->family($family_id);
		$taxon->ortholog->add($os->get_item_by_id($ortholog));
	}
	close IN;
}

sub debug {
	my $self = shift;
	print STDERR "* number of taxon: ", scalar $self->item_list, "\n";
}

1;
