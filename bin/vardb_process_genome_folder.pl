#!/usr/bin/env perl
#

use strict;
use warnings;

system "index_fasta.pl -i protein.fa";
system "index_fasta.pl -i gene.fa";
system "formatdb -i protein.fa -n protein";
system "formatdb -p F -i gene.fa -n gene";
