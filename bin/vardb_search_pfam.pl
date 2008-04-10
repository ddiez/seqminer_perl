#!/usr/bin/env perl

use strict;
use warnings;

use varDB::Config;
use varDB::SearchParam;
#use varDB::SeqIO;
#use varDB::Genome;
#use varDB::Position;
#use varDB::SearchResult;
#use Sets;

my $MODEL_DIR = "$HMMDB/$PFAM_VERSION/";

my $param = new varDB::SearchParam({file => shift});
$param->debug;

while (my $info = $param->next_param) {
	$info->debug;
	
	my $base = $info->family."-".$info->organism_dir;
	
	$param->chdir($info, 'analysis');
	system "hmmpfam $MODEL_DIR/Pfam_ls_b $base-protein.fa > $base-protein-pfam_ls.log";
	system "hmmpfam $MODEL_DIR/Pfam_fs_b $base-protein.fa > $base-protein-pfam_fs.log";
}