package SeqMiner::Download;

sub new {
	my $class = shift;
	
	my $self = {};
	$self->{outdir} = undef;
	$self->{filename} = undef;
	bless $self, $class;
    return $self->_initialize(@_) if @_;
}

sub _initialize {
	my $self = shift;
    my $module = shift;
    $module = "SeqMiner::Download::$module";
    eval "require $module";
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

1;
