package SeqMiner::Parser::ensembl;

use base qw(SeqMiner::Parser);

sub new {
	my $class = shift;
	
	my $self = {};
	bless $self, $class;
	$self->_initialize(@_);
    return $self;
}

sub _initialize {
	my $self = shift;
	print STDERR "[SeqMiner::Parser::ensembl] NOT YET SUPPORTED\n";
}

1;