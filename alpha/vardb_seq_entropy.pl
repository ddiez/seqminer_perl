

use Bio::AlignIO;

my $in = new Bio::AlignIO( -fh => \*STDIN);
my $aln=$in->next_aln;

my $length=$aln->length;
my $nsec=$aln->no_sequences;

# store sequence data.
foreach my $n (1..$nsec) {
	my $seq=$aln->get_seq_by_pos($n);
	my @seq=split(/ */, $seq->seq);
	$seq{$n}->{id}=$seq->display_id;
	$seq{$n}->{seq}=\@seq;
}

# compute entropy for each column.
my @s=();
my @g=();
foreach my $k (0..$length-1) {
	my @col=();
	foreach my $res (1..$nsec) {
		push(@col, $seq{$res}->{seq}->[$k])
	}
	my $s=entropy(\@col, "nogap");
	push(@s, $s);
	print "$s\n";
}
#print_jalview_annotation(\@s);

# compute entropy.
sub entropy {
	my ($seq, $type)=@_;
	my $s=0;
	
	# compute sums.
	my %s=();
	foreach $res (@{$seq}) {
		$s{$res}++;
	}

	# compute frequencies.
	foreach $res (keys %s) {
		next if($res eq "-" and $type="nogap");
		my $p=0;
		$p=$s{$res}/$#{$seq};
		$s+=$p*log($p);
	}

	return(-$s);
}

sub print_jalview_annotation {
	my ($s)=@_;
	print "JALVIEW_ANNOTATION\n";
	print "BAR_GRAPH\tEntropy\t";
	foreach $val (@{$s}) {
		printf "%.2f|", $val;
	}
}
