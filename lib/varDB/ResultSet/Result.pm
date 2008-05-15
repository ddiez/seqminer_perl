package varDB::ResultSet::Result;

use strict;
use warnings;

use varDB::ResultSet::Hit;

sub new {
	my $class = shift;
	
	my $self = {};
	$self->{name} = undef;
	$self->{nhit} = 0;
	$self->{hit_list} = [];
	
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
	return shift->{nhit};
}

sub name {
	my $self = shift;
	$self->{name} = shift if @_;
	return $self->{name};
}

sub hit_list {
	return @{ shift->{hit_list} };
}

sub add_hit {
	my $self = shift;
	my $hit = shift;
	push @{$self->{hit_list}}, $hit;
	$self->{nhit}++;
}

sub get_hit {
	my $self = shift;
	my $n = shift;
	return undef if $n > $self->length;
	return $self->{hit_list}->[$n];
}

sub domains_location_str {
	my $self = shift;
	my %domains;
	my @domain_list;
	foreach my $hit ($self->hit_list) {
		foreach my $hsp ($hit->hsp_list) {
			push @domain_list, $hit->name if !exists $domains{$hit->name};
			#push @{ $domains{$hit->name} }, join "..", $hsp->start, $hsp->end;
			my $chain = $hsp->start."..".$hsp->end."[".$hit->score."|".$hit->significance."]";
			push @{ $domains{$hit->name} }, $chain;
		}
	}
	my @domains;
	foreach my $domain (@domain_list) {
		push @domains, join ":", $domain, join ",", @{ $domains{$domain} };
	}
	return join ";", @domains;
}

sub architecture {
	my $self = shift;
	my %tmp;
	
	foreach my $hit ($self->hit_list) {
		foreach my $hsp ($hit->hsp_list) {
			$tmp{$hsp->start} = $hit->name;
		}
	}
	# now order them by the values.
	my @tmp;
	foreach my $key (sort { $a <=> $b } keys %tmp) {
		push @tmp, $tmp{$key};
	}
	return join ";", @tmp;
}


1;