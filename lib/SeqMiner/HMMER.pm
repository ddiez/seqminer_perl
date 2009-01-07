package SeqMiner::HMMER;

use strict;
use warnings;

use SeqMiner::Config;

sub new {
	my $class = shift;
	
	my $self = {};
	bless $self, $class;
    $self->_initialize(@_);
    return $self;
}

sub _initialize {
	my $self = shift;
}

sub type {
	my $self = shift;
	$self->{type} = shift if @_;
	return $self->{type};
}

# this is to convert dna sequences to protein sequences using two-strands, three reading frames.
sub _process {
	my $self = shift;
	
	my $file = "/tmp/hmmer-tmp.fa";
	my $in = new Bio::SeqIO(-file => $self->file, -format => 'fasta');
	my $out = new Bio::SeqIO(-file => ">$file", -format => 'fasta');
	
	print STDERR "* processing sequences ... ";
	while (my $seq = $in->next_seq) {
		#print STDERR "id: ", $seq->display_id, "\n";
		for my $offset (1 .. 3) {
			#print STDERR "offset: $offset\n";
			for my $strand ((1, -1)) {
				#print STDERR "strand: $strand\n";
				my $seq_ = $seq->new;
				$seq_->seq($seq->seq);
				$seq_->description($seq->description);
				if ($strand == 1) {
					$seq_->display_id($seq->display_id."_+$offset");
				} else {
					$seq_ = $seq_->revcom;
					$seq_->display_id($seq->display_id."_-$offset");
				}
				$out->write_seq($seq_->translate(-offset => $offset));
			}
		}
	}
	$self->file($file);
}

sub run {
	my $self = shift;
	
	if ($self->type eq "hmmsearch") {
		$self->_run_hmmsearch;
	} elsif ($self->type eq "hmmpfam") {
		$self->_run_hmmpfam;
	} else {
		die "unknown search type ".$self->type."\n";
	}
}

sub _run_hmmpsearch {
	my $self = shift;
	
	my $base = "/tmp/foo";
	my $ls = $self->model;
	my $fs = $self->model;
	system "hmmsearch $HMMERPARAM $ls ".$self->file." > $base-protein\_ls.log ";
	system "hmmsearch $HMMERPARAM $fs ".$self->file." > $base-protein\_fs.log ";
}

sub _run_hmmpfam {
	my $self = shift;
	
	system "hmmpfam $HMMERPARAM $VARDB_HOME/db/pfam/Pfam_ls_b /tmp/hmmer-tmp.fa > /tmp/hmmer_ls.log";
	system "hmmpfam $HMMERPARAM $VARDB_HOME/db/pfam/Pfam_fs_b /tmp/hmmer-tmp.fa > /tmp/hmmer_fs.log";
}


1;