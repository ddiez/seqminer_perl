package varDB::OrthologSet;

use strict;
use warnings;
use varDB::Config;
use varDB::Ortholog;
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
	
	open IN, "$VARDB_ORTHOLOG_FILE" or die "$!";
	while (<IN>) {
		next if /^[#|\n]/;
		chomp;
		my ($id, $hmm) = split '\t', $_;
		my $ortholog = $self->get_item_by_id($id);
		if (! defined $ortholog) {
			$ortholog = new varDB::Ortholog($_);
			$ortholog->id($id);
			$self->add($ortholog);
		}
		$ortholog->hmm($hmm);
	}
	close IN;
}

sub ortholog_list {
	return shift->SUPER::item_list;
}

1;