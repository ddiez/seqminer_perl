package SeqMiner::SearchParameter;

use strict;
use warnings;
use SeqMiner::Parameter;
use base "SeqMiner::Parameter";

sub new {
	my $class = shift;
	my $self = $class->SUPER::new(@_);
	#my $self = {};
	bless $self, $class;
    $self->_initialize(@_);
    return $self;
}

sub _initialize {
	my $self = shift;
	$self->{nucleotide} = 1;
	$self->{protein} = 1;
	$self->{type} = "sequence";
	$self->{source} = "genome";
	$self->{mode} = "search";
	$self->{db} = undef;
	$self->{search} = 1;
	$self->{parse} = "normal";
}

sub nucleotide {
	my $self = shift;
	$self->{nucleotide} = shift if @_;
	return $self->{nucleotide};
}

sub protein {
	my $self = shift;
	$self->{protein} = shift if @_;
	return $self->{protein};
}

sub type {
	my $self = shift;
	$self->{type} = shift if @_;
	return $self->{type};
}

sub source {
	my $self = shift;
	$self->{source} = shift if @_;
	return $self->{source};
}

sub db {
	my $self = shift;
	$self->{db} = shift if @_;
	return $self->{db};
}

sub parse {
	my $self = shift;
	$self->{parse} = shift if @_;
	return $self->{parse};
}

sub search {
	my $self = shift;
	$self->{search} = shift if @_;
	return $self->{search};
}

sub mode {
	my $self = shift;
	if (@_) {
		my $nmode = shift;
		my $mode = _check_valid_mode($nmode);
		if (defined $mode) {
			$self->{mode} = $mode;	
		} else {
			print STDERR "WARNING [", ref $self, "]: invalide mode '$nmode'\n";
		}
	}
	return $self->{mode};
}

sub _check_valid_mode {
	my $mode = shift;
	my @modes = ("search", "modelupdate");
	for my $m (@modes) {
		return $m if $m eq $mode;
	}
	return undef;
}


1;