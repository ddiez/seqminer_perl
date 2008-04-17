#!/usr/bin/env perl

use strict;
use warnings;

use varDB::Config;
use varDB::SearchParam;

my $param = new varDB::SearchParam;
$param->debug;
while (my $info = $param->next_param) {
	$info->debug;
	$param->chdir($info, 'nelson');
	my $file = $info->family."-".$info->organism_dir."-nelson.txt";
	print STDERR "* commiting $file\n";
	my $res = system "cp", $file, $VARDB_COMMIT_DIR.$info->super_family;
	die "ERROR [commit]: some error occured commiting files: $!" if $res == -1;
}