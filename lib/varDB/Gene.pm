package varDB::Gene;

use varDB::Exon;
use strict;
use warnings;

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
	$self->{id} = $param->{id};
	$self->{name} = $param->{name};
	$self->{description} = $param->{description};
	$self->{chromosome} = $param->{chromosome};
	$self->{start} = $param->{start};
	$self->{end} = $param->{end};
	$self->{strand} = $param->{strand};
	$self->{source} = $param->{source};
	$self->{exons} = {};
	$self->{exon_list} = [];
	$self->{nexons} = 0;
}

sub id {
	my $self = shift;
	$self->{id} = shift if @_;
	return $self->{id};
}

sub name {
	my $self = shift;
	$self->{name} = shift if @_;
	return $self->{name};
}

sub description {
	my $self = shift;
	$self->{description} = shift if @_;
	return $self->{description};
}

sub chromosome {
	my $self = shift;
	$self->{chromosome} = shift if @_;
	return $self->{chromosome};
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

sub strand {
	my $self = shift;
	$self->{strand} = shift if @_;
	return $self->{strand};
}

sub nexons {
	my $self = shift;
	#$self->{nexons} = shift if @_;
	return $self->{nexons};
}

sub source {
	my $self = shift;
	$self->{source} = shift if @_;
	return $self->{source};
}

sub add_exon {
	my $self = shift;
	my $exon = new varDB::Exon(@_);
	$self->{nexons}++;
	$self->{exons}->{$exon->id} = $exon;
	push @{ $self->{exon_list} }, $exon->id;
}

sub get_exon {
	my $self = shift;
	my $id = shift;
	return $self->{exons}->{$id};
}

sub get_exon_list {
	return shift->{exon_list};
}

1;
