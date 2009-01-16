#!/usr/bin/env perl

use stricts;
use warnings;
use SeqMiner::Download;

# download files.

# process files and copy them to genomes directory.

# format fasta files.
system "formatdb -n protein -p T -i protein.fa";
system "formatdb -n gene -p F -i gene.fa";
system "formatdb -n genome -p F -i genome.fa";
system "formatdb -n est -p F -i est.fa";
