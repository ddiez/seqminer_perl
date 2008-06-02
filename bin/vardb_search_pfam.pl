#!/usr/bin/env perl

use strict;
use warnings;

use varDB::Config;
use varDB::Config::Param;

my $MODEL_DIR = "$HMMDB/$PFAM_VERSION/";

my $param = new varDB::Config::Param;
$param->debug;

while (my $info = $param->next_param) {
	$info->debug;
	
	my $base = $info->family."-".$info->organism_dir;
	my $outdir = $param->dir($info, "pfam");
	
	$param->chdir($info, 'fasta');
	print STDERR "* searching in Pfam_ls ... ";
	system "hmmpfam $HMMERPARAM $MODEL_DIR/Pfam_ls_b $base-protein.fa > $outdir/$base-protein-pfam_ls.log";
	#system "hmmpfam $MODEL_DIR/Pfam_ls_b $base-protein.fa > $outdir/$base-protein-pfam_ls.log";
	print STDERR "OK\n";
	print STDERR "* searcing in Pfam_fs ... ";
	system "hmmpfam $HMMERPARAM $MODEL_DIR/Pfam_fs_b $base-protein.fa > $outdir/$base-protein-pfam_fs.log";
	#system "hmmpfam $MODEL_DIR/Pfam_fs_b $base-protein.fa > $outdir/$base-protein-pfam_fs.log";
	print STDERR "OK\n";
}