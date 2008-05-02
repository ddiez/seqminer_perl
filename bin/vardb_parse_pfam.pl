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

	my $res1 = new varDB::ResultSet({file => "$base-protein-pfam_ls.log"});
	my $res2 = new varDB::ResultSet({file => "$base-protein-pfam_fs.log"});
	
	$param->chdir($info, 'test');
	# workaround to put both results together.
	$res1->export_pfam({file => "$base-pfam.txt", fs => $res2});
	#$res2->export_pfam({file => "$base-protein-pfam_fs.txt"});
}