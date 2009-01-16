package SeqMiner::Parser;

sub new {
	my $class = shift;
	
	my $self = {};
	$self->{outdir};
	$self->{filename};
	bless $self, $class;
    return $self->_initialize(@_) if @_;
}

sub _initialize {
	my $self = shift;
    my $module = shift;
    $module = "SeqMiner::Parser::$module";
    eval "require $module";
    $self->{driver} = $module;
    return $module;
}

sub outdir {
	my $self = shift;
	$self->{outdir} = shift if @_;
	return $self->{outdir};
}

sub filename {
	my $self = shift;
	$self->{filename} = shift if @_;
	return $self->{filename};
}

sub driver {
	my $self = shift;
	$self->{driver} = shift if @_;
	return $self->{driver};
}


1;
