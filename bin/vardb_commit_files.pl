#!/usr/bin/env perl

use strict;
use warnings;

use varDB::Config;
use varDB::SearchParam;

my $param = new varDB::SearchParam;
$param->debug;
while (my $info = $param->next_param) {
	$info->debug;
	my $base = $info->family."-".$info->organism_dir;
	&commit($param, $info, "nelson");
	&commit($param, $info, "test");
	#$param->chdir($info, 'nelson');
	#{
	#	my $file = $base."-nelson.txt";
	#	print STDERR "* commiting $file\n";
	#	my $res = system "cp", $file, $VARDB_COMMIT_DIR."sequences/".$info->super_family;
	#	die "ERROR [commit]: some error occured commiting files: $!" if $res == -1;
	#}
	#
	#$param->chdir($info, 'test');
	#{
	#	my $file = $base."";
	#	print STDERR "* commiting $file\n";
	#	my $res = system "cp", $file, $VARDB_COMMIT_DIR."sequences/".$info->super_family;
	#	die "ERROR [commit]: some error occured commiting files: $!" if $res == -1;
	#}
}

sub commit {
	my $param = shift;
	my $info = shift;
	my $type = shift;
	
	my $base = $info->family."-".$info->organism_dir;
	$param->chdir($info, $type);
	
	my $file = "";
	my $dir = "";
	if ($type eq "nelson") {
		$file = $base."-nelson.txt";
		$dir = "sequences/";
	} elsif ($type eq "test") {
		$file = $base."-pfam.txt";
		$dir = "pfam/";
	}
	
	print STDERR "* commiting $file\n";
	my $res = system "cp", $file, $VARDB_COMMIT_DIR.$dir.$info->super_family;
	die "ERROR [commit]: some error occured commiting files: $!" if $res == -1;
}