package varDB::ResultSet::Hit;

use strict;
use warnings;

use varDB::ResultSet::Hsp;

sub new {
	my $class = shift;
	
	my $self = {};
	$self->{id} = undef;
	$self->{score} = undef;
	$self->{evalue} = undef;
	$self->{start} = undef;
	$self->{end} = undef;
	$self->{nhsp} = 0;
	$self->{hsp_list} = [];
	
	# useful for merging:
	$self->{method} = undef;
	$self->{model} = undef;
	$self->{cutoff} = 1e-02;
	
	bless $self, $class;
    $self->_initialize(@_) if @_;
    return $self;
}

sub _initialize {
	my $self = shift;
	my $param = shift;
	# NOTE: nothing here yet.
}

sub length {
	return shift->{nhsp};
}

sub id {
	my $self = shift;
	$self->{id} = shift if @_;
	return $self->{id};
}

sub score{
	my $self = shift;
	$self->{score} = shift if @_;
	return $self->{score};
}

sub significance {
	my $self = shift;
	$self->{evalue} = shift if @_;
	return $self->{evalue};
}

sub start {
	my $self = shift;
	$self->{start} = shift if @_;
	return $self->{start};
}

sub end {
	my $self = shift;
	$self->{end} = shift if @_;
	return $self->{end};
}

################ useful for merging
sub cutoff {
	my $self = shift;
	$self->{cutoff} = shift if @_;
	return $self->{cutoff};
}

# method used for the search, may be hmmpfam, hmmsearch, genewise.
sub method {
	my $self = shift;
	$self->{method} = shift if @_;
	return $self->{method};
}

# model used for the search.
sub model {
	my $self = shift;
	$self->{model} = shift if @_;
	return $self->{model};
}
################ useful for merging

sub hsp_list {
	return @{ shift->{hsp_list} };
}

sub add_hsp {
	my $self = shift;
	my $hsp = shift;
	push @{$self->{hsp_list}}, $hsp;
	$self->{nhsp}++;
}

sub get_hsp {
	my $self = shift;
	my $n = shift;
	return undef if $n > $self->length;
	return $self->{hsp_list}->[$n];
}

sub get_hsp_by_id {
	my $self = shift;
	my $id = shift;
	foreach my $hsp ($self->hsp_list) {
		if ($hsp->id eq $id) {
			return $hsp;
		}
	}
	return undef;
}

1;