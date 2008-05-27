package varDB::SeqIO;

use Bio::SeqIO;
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
	
	$self->{nseqs} = 0;
	my $in = new Bio::SeqIO(-file => $param->{file}, -format => 'fasta');
	while (my $seq = $in->next_seq) {
		$self->{seqs}->{$seq->display_id}->{seq} = $seq->seq;
		push @{ $self->{seq_list} }, $seq->display_id;
		$self->{nseqs}++;
	}
}

sub get_seq_list {
	return @{ shift->{seq_list} };
}

sub get_seq {
	my $self = shift;
	my $id = shift;
	return $self->{seqs}->{$id}->{seq};
}

sub get_nseqs {
	return shift->{nseqs};
}

sub set_lc {
	my $self = shift;
	foreach my $id ($self->get_seq_list) {
		$self->{seqs}->{$id}->{seq} = lc $self->{seqs}->{$id}->{seq};
	}
}

sub set_uc {
	my $self = shift;
	foreach my $id ($self->get_seq_list) {
		$self->{seqs}->{$id}->{seq} = uc $self->{seqs}->{$id}->{seq};
	}
}

sub subseq {
	my $self = shift;
	my $start = shift;
	my $length = shift;
	my $strand = shift;
	substr $self->seq, $start, $length;
}
1;
