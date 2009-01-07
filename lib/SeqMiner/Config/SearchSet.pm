package SeqMiner::Config::SearchSet;
@ISA = ("SeqMiner::ItemSet");

use strict;
use warnings;

use SeqMiner::ItemSet;
use SeqMiner::Config;
use SeqMiner::TaxonSet;
use SeqMiner::Config::Search;

sub new {
	my $class = shift;
	
	my $self = $class->SUPER::new;
    return $self;
}

sub _initialize {
	my $self = shift;
	my $param = shift;
	
	my $ts = new SeqMiner::TaxonSet;
	
	my $file = $SM_SEARCH_FILE;
	$file = $param->{file} if defined $param->{file};
	open IN, "$file" or die "$!";
	while (<IN>) {
		next if /^[#|\n]/;
		chomp;
		my $search = new SeqMiner::Config::Search($_);
		my $taxon = $ts->get_taxon_by_id($search->taxonid);
		$search->id($self->length);
		$search->organism($taxon->organism);
		$search->strain($taxon->strain);
		$search->organism_dir($taxon->organism_dir);
		$self->add($search);
	}
	close IN;
}

sub next_search {
	return shift->SUPER::next_item;
}

sub search_list {
	return shift->SUPER::item_list;
}

1;