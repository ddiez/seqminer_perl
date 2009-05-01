package SeqMiner::SearchSet;

use strict;
use warnings;

use SeqMiner::Config;
use SeqMiner::OrthologSet;
use SeqMiner::TaxonSet;
use SeqMiner::PaperSet;
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
	my $ps = new SeqMiner::PaperSet;
	my $os = new SeqMiner::OrthologSet;
	
	for my $ortholog ($os->item_list) {
		for my $taxon ($ts->item_list) {
			if ($taxon->ortholog->get_item_by_id($ortholog->id)) {
				my $search = new SeqMiner::SearchSet::Search;
				$search->id($taxon->type.".".$taxon->id.".".$ortholog->id.".".$taxon->family);
				$search->search($taxon);
				$search->family($ortholog);
				$search->type($taxon->type);
				$self->add($search);
			}
		}
		
		for my $paper ($ps->item_list) {
			if ($paper->ortholog->get_item_by_id($ortholog->id)) {
				my $search = new SeqMiner::SearchSet::Search;
				$search->id("paper.".$paper->id.".".$ortholog->id);
				$search->search($paper);
				$search->family($ortholog);
				#$search->keywords($paper->keywords($ortholog->id));
				$search->type('paper');
				$self->add($search);
			}
		}
	}
	
#	foreach my $taxon ($ts->item_list) {
#		#print STDERR "+ ", $taxon->id, "\n";
#		foreach my $family ($taxon->family->item_list) {
#			#print STDERR "  - ", $family->id, "\n";
#			my $search = new SeqMiner::SearchSet::Search($taxon, $family);
#			$search->id($search->taxon->id.".".$search->family->ortholog->id.".".$search->family->id);
#			$self->add($search);
#		}
#	}
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

sub search_sequence {
	my $self = shift;
	foreach my $search ($self->item_list) {
		$search->search_sequence(@_);
	}
}

sub analyze_sequence {
	my $self = shift;
	foreach my $search ($self->item_list) {
		$search->analyze_sequence(@_);
	}
}

sub search_domain {
	my $self = shift;
	foreach my $search ($self->item_list) {
		$search->search_domain(@_);
	}
}

sub analyze_domain {
	my $self = shift;
	foreach my $search ($self->item_list) {
		$search->analyze_domain(@_);
	}
}

sub debug {
	my $self = shift;
	print STDERR "** SEARCHSET\n";
}

1;