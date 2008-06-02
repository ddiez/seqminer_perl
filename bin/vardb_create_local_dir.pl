#!/usr/bin/env perl

use strict;
use warnings;

use varDB::Config;
use varDB::Config::Param;

my $param = new varDB::Config::Param;
$param->create_local_dir_structure;