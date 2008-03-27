package varDB::Position;

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
	
	my $file = $param->{file};
	my $format = $param->{format};
	
	if ($format eq "plasmodb_gff") {
		open IN, $file or die "ERROR [] cannot open file $file: $!\n";
		# this is the parser for PlasmoDB GFF.
		while (<IN>) {
			chomp;
			last if /^##FASTA/; # skip sequences.
			next if /^##/; # skip comments.
			my @line = split '\t', $_;
			my $type = $line[2];
			my $info = $line[8];
			if ($type eq "gene") {
				$info =~ /^ID=.+?\|(.+?);.+?;description=(.+?);/;
				my $id = $1;
				my $desc = $2;
				$self->{gene}->{$id}->{description} = $desc;
				# print $id, "\n";
			} elsif ($type eq "exon") {
				$info =~ /^ID=.+?\|exon_(.+?)-\d+?;/;
				my $id = $1;
				if (! exists $self->{gene}->{$id}) {
					print "warning: $id don't exists.\n";
					next;
				 } else {
					push @{$self->{gene}->{$id}->{exon_start}}, $line[11];
					push @{$self->{gene}->{$id}->{exon_end}}, $line[12];
					$self->{gene}->{$id}->{nexon}++;
				 }
			} # skip other information.
		}
		close IN;
	} elsif ($format eq "kegg_pos") {
	} elsif ($format eq "new") {
		open IN, $file or die "ERROR [] cannot open file $file: $!\n";
		while (<IN>) {
			chomp;
			my ($id, $type, $number, $pos_start, $pos_end) = split '\t', $_;
			#print STDERR "$id\t$type\t$pos_start\t$pos_end\n";
			push @{$self->{gene}->{$id}->{type}}, $type;
			push @{$self->{gene}->{$id}->{number}}, $number;
			push @{$self->{gene}->{$id}->{exon_start}}, $pos_start;
			push @{$self->{gene}->{$id}->{exon_end}}, $pos_end;
			$self->{gene}->{$id}->{nexon}++;
		}
	}# add drivers here.
}

sub get_nexon {
	my $self = shift;
	my $id = shift;
	if (! exists $self->{gene}->{$id}) {
		print STDERR "WARNING [get_nexon]: id $id not found.\n";
		return undef;
	} else {
		return $self->{gene}->{$id}->{nexon};
	}
}


1;
