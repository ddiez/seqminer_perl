package varDB::Parser;

#use varDB::Config;

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

sub driver {
	my $self = shift;
	if (@_) {
		$self->{driver} = $_;
	} else {
		return $self->{driver};
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
	
	$self->{driver} = undef;
	$self->{type} = undef;
	$self->{file} = undef;
	
	# check parameters.
	foreach my $field (keys %{$param}) {
		die "[varDB::Parser] unknown parameter $field.\n" if ! exists $self->{$field};
	}
	
	foreach my $field (keys %{$self}) {
		die "[varDB::Parser] parameter $field is required.\n" if ! exists $param->{$field};
		$self->{$field} = $param->{$field};
	}
	
	$self->{obj} = undef;
	my $in = new Bio::SeqIO(-file => $self->file);
	$self->{obj} = $in;
}

1;

