package varDB::Download;


sub new {
	my $class = shift;
	
	my $self = {};
	bless $self, $class;
    $self->_initialize(@_) if @_;
    return $self;
}

sub _initialize {
	my $self = shift;
}

sub plasmodb {
	my $self = shift;
	
}