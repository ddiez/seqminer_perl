package SeqMiner::AnalyzeSet;

use strict;
use warnings;

use SeqMiner::Analyze;
use SeqMiner::ItemSet;
use base "SeqMiner::ItemSet";

sub new {
	my $class = shift;
	my $self = $class->SUPER::new(@_);
	bless $self, $class;
    return $self;
}

sub _initialize {
	my $self = shift;
}

1;