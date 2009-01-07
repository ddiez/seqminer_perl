package SeqMiner::SeqSet;

use strict;
use warnings;

use SeqMiner::SeqSet::Seq;

sub new {
	my $class = shift;

	my $self = {};
	$self->{seq_list} = [];
	$self->{nseqs} = 0;
	
	bless $self, $class;
	$self->_initialize(@_);
	return $self;
}

sub _initialize {
	my $self = shift;
	my $param = shift;
	if (exists $param->{file}) {
		$self->_read_seq($param->{file});
	}
}

sub length {
	return shift->{nseqs};
}

sub seq_list {
	return @{ shift->{seq_list} };
}

sub add_seq {
	my $self = shift;
	push @{ $self->{seq_list} }, shift;
	$self->{nseqs}++;
}

sub get_seq {
	my $self = shift;
	my $n = shift;
	return $self->{seq_list}->[$n];
}

sub get_seq_by_id {
	my $self = shift;
	my $id = shift;
	
	foreach my $seq ($self->seq_list) {
		if ($seq->id eq $id) {
			return $seq;
		}
	}
	return undef;
}
# parse FASTA header.
sub _parse_fasta_header {
	my $line = shift;
	my $header;
	
	#$line =~ />(.+?)\s(.+)$/;
	$line =~ />\s*(\S+)\s*(.*)/;
	
	my $id = $1;
	my $desc = $2;
	my $spec = undef;
	
	# identify and fix KEGG ids.
	if ($id =~ /^(\w{3,4}):(.+)/) {
		#print STDERR "detected KEGG files\n";
		$spec = $1;
		$id = $2;
	}
	
	# set values.
	$header->{id} = $id;
	$header->{description} = $desc;
	$header->{species} = $spec;
	
	return $header;
}

# interface for reading sequences, currently only FASTA sequences suported.
sub _read_seq {
	my $self = shift;
	my $file = shift;
	my $str = undef;
	my $header_line = undef;
	my $n = 0;

	open IN, "$file" or die "cannot open file $file: $!";
	while (<IN>) {
		chomp;
		if (/>/) {
			if ($n != 0) {
				my $header = _parse_fasta_header($header_line);
				my $seq = new SeqMiner::SeqSet::Seq($header);
				$seq->seq($str);
				$self->add_seq($seq);
			}
			$header_line = $_;
			$str = undef;
			$n++;
		} else {
			# concatenate this seq.
			$str .= $_;
		}
	}
	if (defined $str) {
		my $header = _parse_fasta_header($header_line);
		my $seq = new SeqMiner::SeqSet::Seq($header);
		$seq->seq($str);
		$self->add_seq($seq);
	} else {
		die "ERROR [SeqSet::_read_seq] corrupted file.\n";
	}
	close IN;
}

1;