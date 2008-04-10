#!/usr/bin/env perl

use strict;
use warnings;

use varDB::Config;
use varDB::SearchParam;

my $param = new varDB::SearchParam;
while (my $info = $param->next_param) {
	$param->chdir($info, 'nelson');
	my $file = $info->family."-".$info->organism_dir."-nelson.txt";
	print STDERR "commiting $file\n";
	my $res = system "cp", $file, $VARDB_COMMIT_DIR.$info->super_family;
	die "some error occured commiting files: $!" if $res == -1;
}