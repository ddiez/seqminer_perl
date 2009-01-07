#!/usr/bin/env perl

use strict;
use warnings;

use SeqMiner::Config;
use SeqMiner::Config::Param;
use SeqMiner::ResultSet;

my $param = new SeqMiner::Config::Param({file => shift});
$param->debug;

while (my $info = $param->next_param) {
	$info->debug;
	
	$param->chdir($info, 'pfam');
	my $base = $info->family."-".$info->organism_dir;

	my $ls = new SeqMiner::ResultSet({file => "$base-protein-pfam_ls.log", id => 'ls'});
	my $fs = new SeqMiner::ResultSet({file => "$base-protein-pfam_fs.log", id => 'fs'});

	$param->chdir($info, 'domains');
	SeqMiner::ResultSet::export_pfam({file => "$base-pfam.txt", fs => $fs, ls => $ls});
}