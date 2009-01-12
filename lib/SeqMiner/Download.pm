package SeqMiner::Download;


sub new {
	my $class = shift;
	
	my $self = {};
	bless $self, $class;
    return $self->_initialize(@_) if @_;
    return $self;
}

sub _initialize {
	my $self = shift;
    my $module = shift;
    $module = "SeqMiner::Download::$module";
    eval "require $module";
    return $module;
}

1;
