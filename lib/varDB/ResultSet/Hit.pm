package varDB::ResultSet::Hit;

use strict;
use warnings;

use varDB::ResultSet::Hsp;

sub new {
	my $class = shift;
	
	my $self = {};
	$self->{name} = undef;
	$self->{score} = undef;
	$self->{evalue} = undef;
	$self->{nhsp} = 0;
	$self->{hsp_list} = [];
	
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

sub name {
	my $self = shift;
	$self->{name} = shift if @_;
	return $self->{name};
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

1;