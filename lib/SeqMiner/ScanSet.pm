package SeqMiner::ScanSet;

# methods to scan and annotate sequences. typically programs are:
# 1. hmmpfam - to find Pfam domains
# 2. meme - to find domain in a set of sequences
# 3. mast - to find matches in a set of sequences from a database of motifs (like obtained by meme)

use strict;
use warnings;

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
}

1;