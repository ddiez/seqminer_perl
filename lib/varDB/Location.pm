package varDB::Location;


sub new {
	my $class = shift;
	
	my $self = {};
	bless $self, $class;
    $self->_initialize(@_);
    return $self;
}

sub _initialize {
	my $self = shift;
	
	$self->{id} = undef;
	$self->{type} = undef;
	$self->{start} = undef;
	$self->{end} = undef;
	$self->{exons} = undef;
	$self->{introns} = undef;
	$self->{nlocs} = 0;
}

sub get_number {
	my $self = shift;
	return $self->{nlocs};
}

sub add {
	my $self = shift;
	my $param = shift;
	foreach my $key (keys %{$param}) {
		if (exists $self->{$key}) {
			push @{$self->{$key}}, $param->{$key};
			$self->{nlocs}++;
		} else {
			die "[varDB::Location::add] unknown key $key.\n";
		}
	}
}

1;