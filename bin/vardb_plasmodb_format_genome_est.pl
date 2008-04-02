#!/usr/bin/env perl

use strict;
use warnings;
use Bio::SeqIO;

my $in = new Bio::SeqIO(-file => shift);
my $out = new Bio::SeqIO(-fh => \*STDOUT, -format => 'fasta');
while (my $seq = $in->next_seq) {
	# put everything together (in this case is not needed but safer).
	my $tmp = $seq->display_id.$seq->description;
	my ($org, $chr, $date, $type, $source) = split '\|', $tmp;
	$seq->display_id($chr);
	$seq->description("organism=$org;source=$source;date=$date;type=$type");
	$out->write_seq($seq);
}
