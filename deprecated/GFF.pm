package SeqMiner::GFF;

sub new {
	my $class = shift;
	
	my $self = {};
	bless $self, $class;
    #$self->_initialize(@_);
    return $self;
}

sub parse {
	my $self = shift;
	my $info = shift;
	my $type = shift;
	
	if ($type eq "gene") {
		return _parse_gene_info($info);
	} elsif ($type eq "exon") {
		return _parse_exon_info($info);
	}
}

sub _parse_info {
	my $tmp = shift;
	my $info = {};
	my @tokens = split ";", $tmp;
	foreach my $token (@tokens) {
		$token =~ /(.+)=(.+)/;
		$info->{lc $1} = $2;
	}
	$info->{id} =~ s/apidb\|(.+)/$1/;
	$info->{description} = _unescape($info->{description}) if exists $info->{description};
	return $info;
}

sub _parse_gene_info {
	my $tmp = shift;
	return _parse_info($tmp);
} 

sub _parse_exon_info {
	my $tmp = shift;
	my $info = _parse_info($tmp);
	$info->{parent} =~ s/apidb\|rna_(.+)-.+/$1/;
	$info->{id} =~ s/exon_.+-(.+)/$1/;
	return $info;
}

# from bioperl.
sub _unescape {
	my $v = shift;
	$v =~ tr/+/ /;
	$v =~ s/%([0-9a-fA-F]{2})/chr hex($1)/ge;
	return $v;
}

1;
