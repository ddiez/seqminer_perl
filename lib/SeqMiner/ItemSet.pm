package SeqMiner::ItemSet;

use strict;
use warnings;

sub new {
	my $class = shift;

	my $self = {};
	$self->{item_list} = [];
	$self->{nitems} = 0;
	
	bless $self, $class;
	return $self;
}

sub length {
	return shift->{nitems};
}

sub add {
	my $self = shift;
	my $item = shift;
	$item->super($self);
	push @{ $self->{item_list} }, $item;
	$self->{items}->{$item->id} = $item;
	$self->{nitems}++;
}

sub get_item_by_id {
	my $self = shift;
	my $id = shift;
	if (exists $self->{items}->{$id}) {
		return $self->{items}->{$id};
	} else {
		return undef;
	}
}

sub get_item_by_pos {
	my $self = shift;
	return $self->{item_list}->[shift];
}

sub item_list {
	my $self = shift;
	return @{ $self->{item_list} };
	return undef;
}

{ # other option would be to store n in the class itself.
	my $n = 0;
	sub next_item {
		my $self = shift;
		return $self->{item_list}->[$n++];
	}
	
	sub rewind {
		my $self = shift;
		$n = 0;
	}
}


1;