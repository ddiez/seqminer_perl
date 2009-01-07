#!/usr/bin/env perl

use strict;
use warnings;

use SeqMiner::Config;
use SeqMiner::Config::Param;

my $param = new SeqMiner::Config::Param;
$param->debug;
while (my $info = $param->next_param) {
	$info->debug;
	my $base = $info->family."-".$info->organism_dir;
	&commit($param, $info, "sequences");
	&commit($param, $info, "domains");
}

sub commit {
	my $param = shift;
	my $info = shift;
	my $type = shift;
	
	my $base = $info->family."-".$info->organism_dir;
	$param->chdir($info, $type);
	
	my $file = "";
	my $dir = "";
	if ($type eq "sequences") {
		$file = $base.".txt";
		$dir = "sequences/";
	} elsif ($type eq "domains") {
		$file = $base."-pfam.txt";
		$dir = "pfam/";
	}
	
	print STDERR "* commiting $file\n";
	my $res = system "cp", $file, $SM_COMMIT_DIR.$dir.$info->super_family;
	die "ERROR [commit]: some error occured commiting files: $!" if $res == -1;
}