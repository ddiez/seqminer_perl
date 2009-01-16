package SeqMiner::Parser::broad;

use base qw(SeqMiner::Parser);

sub new {
	my $class = shift;
	
	my $self = {};
	bless $self, $class;
    return $self;
}

1;