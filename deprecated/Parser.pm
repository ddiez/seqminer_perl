package SeqMiner::Parser;

#use SeqMiner::Config;

use strict;
use warnings;
use Bio::SeqIO;

sub new {
    my $class = shift;
    my $self = {};
    bless $self, $class;
    $self->_initialize(@_);
    return $self;
}

sub file {
	my $self = shift;
	if (@_) {
		$self->{file} = $_;
	} else {
		return $self->{file};
	}
}

sub format {
	my $self = shift;
	if (@_) {
		$self->{format} = $_;
	} else {
		return $self->{format};
	}
}

sub type {
	my $self = shift;
	if (@_) {
		$self->{type} = $_;
	} else {
		return $self->{type};
	}
}

sub _initialize {
    my $self = shift;
    my $param = shift;
	
	$self->{format} = undef;
	$self->{type} = undef;
	$self->{file} = undef;
	
	# check parameters.
	foreach my $field (keys %{$param}) {
		die "[SeqMiner::Parser] unknown parameter $field.\n" if ! exists $self->{$field};
	}
	
	foreach my $field (keys %{$self}) {
	#	die "[SeqMiner::Parser] parameter $field is required.\n" if ! exists $param->{$field};
		$self->{$field} = $param->{$field};
	}
	
	$self->{instance} = undef;
	my $in = new Bio::SeqIO(-file => $self->file, -format => $self->format);
	$self->{instance} = $in;
}

sub instance {
	my $self = shift;
	return $self->{instance};
}

1;

