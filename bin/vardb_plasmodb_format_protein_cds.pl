#!/usr/bin/env perl

use strict;
use warnings;
use Bio::SeqIO;

my $in = new Bio::SeqIO(-file => shift);
my $out = new Bio::SeqIO(-fh => \*STDOUT, -format => 'fasta');
while (my $seq = $in->next_seq) {
	my $tmp = $seq->display_id." ".$seq->description;
	my ($org, $chr, $id, $what, $source, $desc) = split '\|', $tmp;
	$seq->display_id($id);
	$seq->description("description=$desc;organism=$org;source=$source;chromosome=$chr");
	$out->write_seq($seq);
}
