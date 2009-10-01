package SeqMiner::DownloadSet;

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
}

1;