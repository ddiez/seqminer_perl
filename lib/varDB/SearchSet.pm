package SeqMiner::SearchSet;

use strict;
use warnings;

use SeqMiner::Config;
use SeqMiner::TaxonSet;
use SeqMiner::SearchSet::Search;
use SeqMiner::ItemSet;
use vars qw( @ISA );
@ISA = ("SeqMiner::ItemSet");

sub new {
	my $class = shift;
	
	my $self = {};
	bless $self, $class;
    $self->_initialize(@_);
    return $self;
}

sub _initialize {
	my $self = shift;
	
	my $ts = new SeqMiner::TaxonSet;
	
	foreach my $taxon ($ts->item_list) {
		#print STDERR "+ ", $taxon->id, "\n";
		foreach my $family ($taxon->family->item_list) {
			#print STDERR "  - ", $family->id, "\n";
			my $search = new SeqMiner::SearchSet::Search($taxon, $family);
			$search->id($search->taxon->id.".".$search->family->ortholog->id.".".$search->family->id);
			$self->add($search);
		}
	}
}

sub seed {
	my $self = shift;
	foreach my $search ($self->item_list) {
		if ($search->taxon->seed) {
			$search->seed;
		}
	}
}

sub hmm {
	my $self = shift;
	foreach my $search ($self->item_list) {
		$search->hmm;
	}
}

sub search {
	my $self = shift;
	foreach my $search ($self->item_list) {
		$search->search(@_);
	}
}

sub analyze {
	my $self = shift;
	foreach my $search ($self->item_list) {
		$search->analyze;
	}
}

sub debug {
	my $self = shift;
	print STDERR "** SEARCHSET\n";
}

1;