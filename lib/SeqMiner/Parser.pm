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

sub format {
	my $self = shift;
	
	chdir $self->outdir;
	print STDERR "* formating genome (blast) ... ";
	system "formatdb -p F -i genome.fa -n genome -o T -V";
	print STDERR "OK\n";
	print STDERR "* formating gene (blast) ... ";
	system "formatdb -p F -i gene.fa -n gene -o T -V";
	print STDERR "OK\n";
	print STDERR "* formating protein (blast) ... ";
	system "formatdb -i protein.fa -n protein -o T -V";
	print STDERR "OK\n";
}


1;
