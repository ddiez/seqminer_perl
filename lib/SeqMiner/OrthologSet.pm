package SeqMiner::OrthologSet;

use strict;
use warnings;
use SeqMiner::Config;
use SeqMiner::Ortholog;
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
	
	open IN, "$SM_ORTHOLOG_FILE" or die "$!";
	while (<IN>) {
		next if /^[#|\n]/;
		chomp;
		my ($id, $hmm) = split '\t', $_;
		my $ortholog = $self->get_item_by_id($id);
		if (! defined $ortholog) {
			$ortholog = new SeqMiner::Ortholog($_);
			$ortholog->id($id);
			$self->add($ortholog);
		}
		$ortholog->hmm($hmm);
	}
	close IN;
}

sub name {
	shift->id(@_);
}

sub ortholog_list {
	return shift->SUPER::item_list;
}

sub filter_by_ortholog_name {
	my $self = shift;
	my $filter = shift;
	return $self if $#{$filter} == -1;
	my $ts = new SeqMiner::OrthologSet({empty => 1});
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
sub debug {
	my $self = shift;
	print STDERR "#---", ref $self, "--->\n";
	print STDERR "* number of orthologs: ", $self->length, "\n";
	for my $o ($self->item_list) {
		print STDERR "* ", $o->name, "\t", $o->hmm, "\n";
	}
	print STDERR "\\\\\n";
}

1;
