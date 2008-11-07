package varDB::SearchSet;

use strict;
use warnings;

use varDB::Config;
use varDB::TaxonSet;
use varDB::SearchSet::Search;
use varDB::ItemSet;
use vars qw( @ISA );
@ISA = ("varDB::ItemSet");

sub new {
	my $class = shift;
	
	my $self = {};
	bless $self, $class;
    $self->_initialize(@_);
    return $self;
}

sub _initialize {
	my $self = shift;
	
	my $ts = new varDB::TaxonSet;
	
	foreach my $taxon ($ts->item_list) {
		#print STDERR "+ ", $taxon->id, "\n";
		foreach my $family ($taxon->family->item_list) {
			#print STDERR "  - ", $family->id, "\n";
			my $search = new varDB::SearchSet::Search($taxon, $family);
			$search->id($search->taxon->id.".".$search->family->ortholog->id.".".$search->family->id);
			$self->add($search);
		}
	}
}

sub search {
	my $self = shift;
	foreach my $search ($self->item_list) {
		$search->search;
	}
}

sub analyze {
	my $self = shift;
	foreach my $search ($self->item_list) {
		$search->analyze;
	}
}

1;