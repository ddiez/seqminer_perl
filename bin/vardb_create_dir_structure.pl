#!/usr/bin/env perl

use strict;
use warnings;
use varDB::Config;
use varDB::OrthologSet;

my $os = new varDB::OrthologSet;

my $force_new = 1; # forces new dir structure.

my @DIR_BASE = ("isolate", "genome", "paper");
my @DIR_SUB = ('search', 'analysis', 'sequences', 'pfam', 'fasta', 'domains');


if ($force_new) {
	chdir "$VARDB_MINING_DIR";
	
	if (! -d $VARDB_SEARCH_DIR) {
		print "no dir! (use force to create news)\n";
	}
	
	my $dir = undef;
	if ($DEBUG == 1) {
		$dir = &_get_random_dir;
	} else {
		$dir = "vardb-$VARDB_RELEASE";
	}
	mkdir $dir;
	unlink "last";
	system "ln -s $dir last";
	
	chdir $dir;
	foreach my $dir (@DIR_BASE) {
		mkdir $dir;
		chdir $dir;
		foreach my $dirs (@DIR_SUB) {
			mkdir $dirs;
			chdir $dirs;
			foreach my $ortholog ($os->item_list) {
				mkdir $ortholog->id;
			}
			chdir "..";
		}
		chdir "..";
	}
}

sub _get_random_dir {
	my @time = localtime time;
	$time[5] += 1900;
	$time[4] ++;
	$time[4] = sprintf("%02d", $time[4]);
	$time[3] = sprintf("%02d", $time[3]);
	$time[2] = sprintf("%02d", $time[2]);
	$time[1] = sprintf("%02d", $time[1]);
	$time[0] = sprintf("%02d", $time[0]);
	
	return "$time[5]$time[4]$time[3].$time[2]$time[1]$time[0]";
}