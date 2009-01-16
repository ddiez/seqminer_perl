#!/usr/bin/env perl

use strict;
use warnings;

use SeqMiner::Config;
#use SeqMiner::Config::Param;
#use SeqMiner::TaxonSet;
use SeqMiner::ResultSet;


my $ls = new SeqMiner::ResultSet({file => shift, id => 'ls'});
my $fs = new SeqMiner::ResultSet({file => shift, id => 'fs'});

SeqMiner::ResultSet::export_pfam({file => "pfam.txt", fs => $fs, ls => $ls});