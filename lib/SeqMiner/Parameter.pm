package SeqMiner::Parameter;

use strict;
use warnings;
#use SeqMiner::ItemSet;
#use base "SeqMiner::ItemSet";

sub new {
	my $class = shift;
	#my $self = $class->SUPER::new(@_);
	my $self = {};
	bless $self, $class;
    $self->_initialize(@_);
    return $self;
}

sub _initialize {
	my $self = shift;
}

sub debug {
	my $self = shift;
	print "#--- ", ref $self, "--->\n";
	for my $param (keys %{$self}) {
		print STDERR "* ", $param, ": ", defined $self->{$param} ? $self->{$param} : "_undef_", "\n";
	}
}

1;