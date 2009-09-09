package SeqMiner::Config2;

sub new {
	my $class = shift;
	
	my $self = {};
	bless $self, $class;
    $self->_initialize(@_);
    return $self;
}

sub _initialize {
	my $self = shift;
	my $param = shift;
	
	$self->{release} = 1;
	$self->{debug} = 1;
	
	$self->{dir}->{home} = "/Volumes/Data/projects/vardb"; # maybe make undef by default.
	$self->{dir}->{commit} = "$self->{dir}->{home}/web/trunk/data/diego/";
	$self->{dir}->{mining} = "$self->{dir}->{home}/mining";
	$self->{dir}->{search} = "$self->{dir}->{home}/$self->{dir}->{mining}/vardb-$self->{release}";
	$self->{dir}->{search} = "$self->{dir}->{home}/$self->{dir}->{mining}/last" if $self->{debug};
	
	$self->{file}->{organism} = "$self->{dir}->{home}/etc/organisms.txt";
	$self->{file}->{taxon} = "$self->{dir}->{home}/etc/taxon.txt";
	$self->{file}->{filter} = "$self->{dir}->{home}/etc/filter.txt";
	$self->{file}->{paper} = "$self->{dir}->{home}/etc/paper.txt";
	$self->{file}->{author} = "$self->{dir}->{home}/etc/author.txt";
	$self->{file}->{keyword} = "$self->{dir}->{home}/etc/keyword.txt";
	$self->{file}->{ortholog} = "$self->{dir}->{home}/etc/ortholog.txt";

	$self->{db}->{uniprot} = "$self->{dir}->{home}/db/uniprot";
	$self->{db}->{pdb} = "$self->{dir}->{home}/db/pdb";
	$self->{db}->{hmm} = "$self->{dir}->{home}/db/pfam";
	$self->{db}->{genome} = "$self->{dir}->{home}/db/genome";
	
	$self->{program}->{hmmer}->{evalue} = 1e-02;
	$self->{program}->{hmmer}->{cpu} = 1;
	$self->{program}->{wise}->{cpu} = 1;
	$self->{program}->{wise}->{alignments} = 500;
	$self->{program}->{psiblast}->{evalue} = 1e-03;
	$self->{program}->{psiblast}->{iter} = 3;
	
	$self->{alias}->{nuccore} = "core";
	$self->{alias}->{nucest} = "est";
	
	$self->_read_config($param->{file}) if exists $param->{file};
	
}

sub _read_config {
	my $self = shift;
	my $file = shift;
	
	return if ! defined $file;
	print STDERR "Reading CUSTOM CONFIG ... ";
	
	open IN, "$file" or die "Config2 ERROR: $file | $!\n";
	while (<IN>) {
		chomp;
		my ($tag, $value) = split '=', $_;
		my @tag = split '_', lc $tag;
		if ($tag[0] eq "dir") {
			$self->{$tag[0]}->{$tag[1]} = $value if exists $self->{$tag[0]}->{$tag[1]};
		} elsif ($tag[0] eq "file") {
			$self->{$tag[0]}->{$tag[1]} = $value if exists $self->{$tag[0]}->{$tag[1]};
		} elsif ($tag[0] eq "db") {
			$self->{$tag[0]}->{$tag[1]} = $value if exists $self->{$tag[0]}->{$tag[1]};
		} elsif ($tag[0] eq "program") {
			$self->{$tag[0]}->{$tag[1]}->{$tag[2]} = $value if exists $self->{$tag[0]}->{$tag[1]}->{$tag[2]};
		} elsif ($tag[0] eq "alias") {
			$self->{$tag[0]}->{$tag[1]} = $value if exists $self->{$tag[0]}->{$tag[1]};
		} else {
			print STDERR "Undefined TAG: $tag[0] in $tag.\n";
		}
	}
	close IN;
	
	print STDERR "OK\n";
}

sub dir {
	my $self = shift;
	my $what = shift;
	return undef if ! exists $self->{$what};
	$self->{$what} = shift if @_;
	return $self->{$what};
}

sub file {
	my $self = shift;
	my $what = shift;
	return undef if ! exists $self->{$what};
	$self->{$what} = shift if @_;
	return $self->{$what};
}

sub db {
	my $self = shift;
	my $what = shift;
	return undef if ! exists $self->{$what};
	$self->{$what} = shift if @_;
	return $self->{$what};
}

sub program {
	my $self = shift;
	my $what = shift;
	my $which = shift;
	return undef if ! exists $self->{$what};
	return undef if ! exists $self->{$what}->{$which};
	$self->{$what} = shift if @_;
	return $self->{$what};
}

sub alias {
	my $self = shift;
	my $what = shift;
	return undef if ! exists $self->{$what};
	$self->{$what} = shift if @_;
	return $self->{$what};
}

sub debug {
	my $self = shift;
	print STDERR "CONFIG for SEQMINER: ", $self->{release}, "\n";
	for my $key (keys %{$self}) {
		print STDERR "* $key\n";
		for my $subkey (keys %{ $self->{$key} }) {
			print STDERR "  > $subkey : $self->{$key}->{$subkey}\n";
		}
	}
}

1;