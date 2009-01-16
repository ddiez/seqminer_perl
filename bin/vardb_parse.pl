#!/usr/bin/env perl

use strict;
use warnings;
#
# This is a general purpose script for parsing data from genome sources.
#
#
use SeqMiner::Parser;
use Getopt::Long;

my %O;
GetOptions(\%O, 'i:s', 'd:s', 'format:s');

my $help = <<"HELP";

#!! WARNING !!
#  This is a general purpose script for parsing data from genome sources.
#!! WARNING !!

Usage:

 vardb_parse.pl -i <file> -d -format <format>

Options:

   -i   file in Genbank format
   -d   directory to output data
   -f   source format (ncbi, plasmodb, broad) [default: null]
 
HELP

die $help if !exists $O{i};
die $help if !exists $O{f};

my $parser = new SeqMiner::Parser($O{format});
$parser->parse;