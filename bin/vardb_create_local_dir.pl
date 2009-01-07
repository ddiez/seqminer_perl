#!/usr/bin/env perl

use strict;
use warnings;

use SeqMiner::Config;
use SeqMiner::Config::Param;

my $param = new SeqMiner::Config::Param;
$param->create_local_dir_structure;