package SeqMiner::DownloadSet;

use strict;
use warnings;
use SeqMiner::Config;
use SeqMiner::Ortholog;
use SeqMiner::ItemSet;
use SeqMiner::TaxonSet;
use SeqMiner::TaxonSet::Taxon;
use SeqMiner::Download;
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
}


sub add {
	my $self = shift;
	my $ts = shift;
	for my $t ($ts->item_list) {
		my $d = new SeqMiner::Download;
		$d->debug;
		$d->taxon($t);
		$self->SUPER::add($d);
	}
}

sub debug {
	my $self = shift;
	print STDERR "#---", ref $self, "--->\n";
	print STDERR "* number of downloads: ", $self->length, "\n";
	for my $d ($self->item_list) {
		print STDERR "* ", $d->taxon->name, "\n";
	}
	print STDERR "\\\\\n";
}

1;