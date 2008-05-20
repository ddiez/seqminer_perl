#!/usr/bin/env perl

use strict;
use warnings;

use varDB::Config;
use varDB::SearchParam;
use varDB::ResultSet;
#use varDB::SearchPfam;

my $param = new varDB::SearchParam({file => shift});
$param->debug;

while (my $info = $param->next_param) {
	$info->debug;
	
	$param->chdir($info, 'pfam');
	my $base = $info->family."-".$info->organism_dir;

	my $ls = new varDB::ResultSet({file => "$base-protein-pfam_ls.log", id => 'ls'});
	my $fs = new varDB::ResultSet({file => "$base-protein-pfam_fs.log", id => 'fs'});

	$param->chdir($info, 'test');
	varDB::ResultSet::export_pfam({file => "$base-pfam.txt", fs => $fs, ls => $ls});
}