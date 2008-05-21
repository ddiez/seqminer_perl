#!/usr/bin/env perl

use strict;
use warnings;

use varDB::Config;
use varDB::Config::Param;
use varDB::SeqIO;
use varDB::Genome;
use varDB::ResultSet;
use Sets;

my $param = new varDB::SearchParam({file => shift});
$param->debug;

while (my $info = $param->next_param) {
	$info->debug;
	
	my $family = $info->family;
	my $organism_dir = $info->organism_dir;
	my $base = "$family-$organism_dir";
	
	# compute position file (from genome).
	my $genome = new varDB::Genome({file => "$GENOMEDB/$organism_dir/genome.gff"});
	#my $pos = $genome->to_position; # temp fix.

	# read result files.
	$param->chdir($info, 'search');
	my $rs = new varDB::ResultSet({file => "$base-protein_ls.log", id => 'protein_ls'});
	$rs->add({file => "$base-protein_fs.log", id => 'protein_fs'});
	$rs->add({file => "$base-gene_ls-genewise.log", id => 'gene_ls'});
	$rs->add({file => "$base-gene_fs-genewise.log", id => 'gene_fs'});
	
	my $p_ls = $rs->get_result_by_id('protein_ls');
	my $p_fs = $rs->get_result_by_id('protein_fs');
	my $g_ls = $rs->get_result_by_id('gene_ls');
	my $g_fs = $rs->get_result_by_id('gene_fs');
	
	#my $p_ls = new varDB::ResultSet({file => "$base-protein_ls.log", id => 'protein_ls'});
	#my $p_fs = new varDB::ResultSet({file => "$base-protein_fs.log", id => 'protein_fs'});
	#my $g_ls = new varDB::ResultSet({file => "$base-gene_ls.log", id => 'gene_ls'});
	#my $g_fs = new varDB::ResultSet({file => "$base-gene_fs.log", id => 'gene_fs'});
	
	my $np_ls = $p_ls->length;
	my $np_fs = $p_fs->length;
	my $ngg_ls = $g_ls->length;
	my $ngg_fs = $g_fs->length;
	
	my $pset = new Sets($p_ls->hit_ids, $p_fs->hit_ids);
	my $gset = new Sets($g_ls->hit_ids, $g_fs->hit_ids);
	
	my $pi = $pset->intersect;
	my $pu = $pset->union;
	my $npi = $pi->get_items(0);
	my $npu = $pu->get_items(0);
	
	my $gi = $gset->intersect;
	my $gu = $gset->union;
	my $ngi = $gi->get_items(0);
	my $ngu = $gu->get_items(0);
	
	# print number of sequences.
	#$param->chdir($info, 'analysis');
	#$rs->export_number({file => "$base-number.txt"});
	# deprecated.
	#open NUMBER, ">>number.txt" or die "$!";
	#print NUMBER "$np_ls\t$family\t$organism_dir\tprotein_ls\n";
	#print NUMBER "$np_fs\t$family\t$organism_dir\tprotein_fs\n";
	#print NUMBER "$ngg_ls\t$family\t$organism_dir\tgene_ls-gw\n";
	#print NUMBER "$ngg_fs\t$family\t$organism_dir\tgene_fs-gw\n";
	#print NUMBER "$npu\t$family\t$organism_dir\tprotein union\n";
	#print NUMBER "$npi\t$family\t$organism_dir\tprotein intersect\n";
	#print NUMBER "$ngu\t$family\t$organism_dir\tgene union\n";
	#print NUMBER "$ngi\t$family\t$organism_dir\tgene intersect\n";
	#close NUMBER;
	
	# merge different results.
	$p_ls->merge($p_fs);
	$g_ls->merge($g_fs);
	$p_ls->merge($g_ls);
	
	# read sequence files.
	my $pro = new varDB::SeqIO({file => "$GENOMEDB/$organism_dir/protein.fa"});
	my $nuc = new varDB::SeqIO({file => "$GENOMEDB/$organism_dir/gene.fa"});
	
	# export in nelson's format.
	$param->chdir($info, 'nelson');
	$p_ls->export_nelson({file => "$base-nelson.txt", info => $info,
						   protein => $pro, nucleotide => $nuc,
						   genome => $genome});
	
	# export FASTA file.
	$param->chdir($info, 'fasta');
	$p_ls->export_fasta({file => "$base-protein.fa", db => $pro});
	$p_ls->export_fasta({file => "$base-nucleotide.fa", db => $nuc});
}
