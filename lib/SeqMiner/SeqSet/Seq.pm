package SeqMiner::SeqSet::Seq;

use strict;
use warnings;

sub new {
	my $class = shift;

	my $self = {};
	$self->{id} = undef;
	$self->{description} = undef;
	$self->{length} = undef;
	$self->{seq} = undef;
	$self->{species} = undef;

	bless $self, $class;
	$self->_initialize(@_);
	return $self;
}

sub _initialize {
	my $self = shift;
	my $param = shift;
	# TODO: check for valid parameters.
	for my $key (keys %{$param}) {
		if (! exists $self->{$key}) {
			print STDERR "invalid key $key\n";
		} else {
			$self->{$key} = $param->{$key};
		}
	}
}

sub id {
	my $self = shift;

	$self->{id} = shift if(@_);
	return $self->{id};
}

sub description {
	my $self = shift;

	$self->{description} = shift if(@_);
	return $self->{description};
}

sub length {
	my $self = shift;

	return $self->{length};
}

sub seq {
	my $self = shift;

	if(@_) {
		$self->{seq} = shift;
		$self->{length} = CORE::length $self->{seq};
	}
	return $self->{seq};
}

sub species {
	my $self = shift;
	
	if (@_) {
		$self->{species} = shift;
	}
	return $self->{species};
}

sub print {
	my $self = shift;
	my $seq = $self->seq;
	$seq =~ s/(.{60})/$1\n/g;
	print ">$self->{id} $self->{description}\n";
	print "$seq\n";
}

sub complement {
	my $self = shift;
	my $seq = $self->{seq};
	$seq =~ tr/atgcATGC/tacgTAGC/;
	return $seq;
}

sub subseq {
	my $self = shift;
	my $start = shift;
	my $length = shift;
	my $strand = shift;
	
	if ($length < 0) {
		$start -= $length;
		$length = abs $length;
	}
	
	my $subseq = new SeqMiner::SeqSet::Seq;
	$subseq->id($self->id);
	$subseq->description($strand);
	$subseq->seq(substr $self->{seq}, $start, $length);
	
	if ($strand eq "-") {
		$subseq->seq($subseq->complement);
	}
	
	return $subseq;
}

1;
