#!/usr/bin/env perl

use strict;
use warnings;

use varDB::Config;
use varDB::SearchParam;

my $MODEL_DIR = "$HMMDB/$PFAM_VERSION/";

my $param = new varDB::SearchParam({file => shift});
$param->debug;

while (my $info = $param->next_param) {
	$info->debug;
	
	my $base = $info->family."-".$info->organism_dir;
	my $outdir = $param->dir($info, "pfam");
	
	$param->chdir($info, 'analysis');
	print STDERR "* searching in Pfam_ls ... ";
	system "hmmpfam $MODEL_DIR/Pfam_ls_b $base-protein.fa > $outdir/$base-protein-pfam_ls.log";
	print STDERR "OK\n";
	print STDERR "* searcing in Pfam_fs ... ";
	system "hmmpfam $MODEL_DIR/Pfam_fs_b $base-protein.fa > $outdir/$base-protein-pfam_fs.log";
	print STDERR "OK\n";
}