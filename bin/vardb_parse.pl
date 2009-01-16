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
GetOptions(\%O, 'i:s', 'd:s', 'format:s', 't');

my $help = <<"HELP";

#!! WARNING !!
#  This is a general purpose script for parsing data from genome sources.
#!! WARNING !!

Usage:

 vardb_parse.pl -i <file> -d -format <format>

Options:

   -i   input file
   -o   output directory
   -f   source format (ncbi, plasmodb, broad) [default: null]
   -t   file type (for broad driver)
   -d   description file (for broad driver)
 
HELP

die $help if !exists $O{i};
die $help if !exists $O{f};

my $parser = new SeqMiner::Parser($O{format});
$parser->parse($O{t}, $O{d});
$parser->format;