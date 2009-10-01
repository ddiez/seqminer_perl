package SeqMiner::AnalyzeSet;

use strict;
use warnings;

use SeqMiner::Analyze;
use SeqMiner::ItemSet;
use base "SeqMiner::SearchSet";

sub new {
	my $class = shift;
	my $self = $class->SUPER::new(@_);
	bless $self, $class;
    return $self;
}

sub _initialize {
	my $self = shift;
	shift->SUPER::_initialize(@_);
}

sub analyze {
	shift->SUPER::search(@_);
}

1;