package SeqMiner::Parser::plasmodb;

use base qw(SeqMiner::Parser);

sub new {
	my $class = shift;
	
	my $self = {};
	bless $self, $class;
    return $self;
}

1;