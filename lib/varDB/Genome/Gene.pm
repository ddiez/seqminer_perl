package varDB::Genome::Gene;

use varDB::Genome::Exon;
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
	return $self->{nexons};
}

sub source {
	my $self = shift;
	$self->{source} = shift if @_;
	return $self->{source};
}

sub exon_list {
	return @{ shift->{exon_list} };
}

sub add_exon {
	my $self = shift;
	my $exon = shift;
	push @{ $self->{exon_list} }, $exon;
	$self->{nexons}++;
}

sub get_exon {
	my $self = shift;
	my $n = shift;
	return $self->{exon_list}->[$n];
}

sub get_exon_by_id {
	my $self = shift;
	my $id = shift;
	foreach my $exon ($self->exon_list) {
		if ($exon->id eq $id) {
			return $exon;
		}
	}
	return undef;
}

1;
