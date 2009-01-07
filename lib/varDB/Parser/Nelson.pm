package SeqMiner::Parser::Nelson;

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
	
	open IN, "$param->{file}" or die "cannot open file $param->{file}: $!\n";
	my $header = <IN>;
	$self->_init_headers($header);
	my $N = 0;
	while (<IN>) {
		chomp;
		my @line = split '\t', $_;
		foreach my $n (0 .. $#line) {
			$self->{$N}->{$self->header($n)} = $line[$n];
		}
		$N++;
	}
	close IN;
	$self->{nrow} = $N;
}

sub _init_headers {
	my $self = shift;
	my @header = split '\t', shift;
	$self->{ncol} = scalar @header;
	$self->{header} = \@header;
}

sub ncol {
	return shift->{ncol};
}

sub nrow {
	return shift->{nrow};
}

sub header {
	my $self = shift;
	return $self->{header}->[shift];
}

sub id {
	my $self = shift;
	my $n = shift;
	return $self->{$n}->{SEQUENCE};
}

sub id_list {
	my $self = shift;
	my @id_list;
	foreach my $n (0 .. $self->nrow - 1) {
		push @id_list, $self->{$n}->{SEQUENCE};
	}
	return @id_list;
}

1;