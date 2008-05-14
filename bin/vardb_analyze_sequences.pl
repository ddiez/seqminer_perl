#!/usr/bin/env perl

use strict;
use warnings;

use varDB::Config;
use varDB::SearchParam;
use varDB::SeqIO;
use varDB::Genome;
use varDB::Position;
use varDB::SearchResult;
use Sets;

my $param = new varDB::SearchParam({file => shift});
$param->debug;

while (my $info = $param->next_param) {
	$info->debug;
	
	my $family = $info->family;
	my $organism_dir = $info->organism_dir;
	my $eexons = $info->eexons;
	my $base = "$family-$organism_dir";
	
	# read position file.
	#my $pos = new varDB::Position({file => "$GENOMEDB/$organism_dir/position.txt",
	#							   format => $info->format});
	my $genome = new varDB::Genome({file => "$GENOMEDB/$organism_dir/genome.gff"});
	my $pos = $genome->to_position; # temp fix.

	# read list file.
	$param->chdir($info, 'search');
	#my $lp = new varDB::SearchResult({file => "$base-protein.log", method => 'psiblast'});
	#my $lg = new varDB::SearchResult({file => "$base-gene.log", method => 'psiblast'});
	my $lp_ls = new varDB::SearchResult({file => "$base-protein_ls.log"});
	my $lp_fs = new varDB::SearchResult({file => "$base-protein_fs.log"});
	#my $lg_ls = new varDB::SearchResult({file => "$base-gene_ls.log"});
	#my $lg_fs = new varDB::SearchResult({file => "$base-gene_fs.log"});
	my $lgg_ls = new varDB::SearchResult({file => "$base-gene_ls-genewise.log"});
	my $lgg_fs = new varDB::SearchResult({file => "$base-gene_fs-genewise.log"});
	
	$param->chdir($info, 'analysis');
	#my $np = $lp->length;
	#my $ng = $lg->length;
	my $np_ls = $lp_ls->length;
	my $np_fs = $lp_fs->length;
	#my $ng_ls = $lg_ls->length;
	#my $ng_fs = $lg_fs->length;
	my $ngg_ls = $lgg_ls->length;
	my $ngg_fs = $lgg_fs->length;
	
	# compute sets stuff.
	my $pset = new Sets($lp_ls->id_list, $lp_fs->id_list);
	my $gset = new Sets($lgg_ls->id_list, $lgg_fs->id_list);
	
	my $pi = $pset->intersect;
	my $pu = $pset->union;
	my $npi = $pi->get_items(0);
	my $npu = $pu->get_items(0);
	
	my $gi = $gset->intersect;
	my $gu = $gset->union;
	my $ngi = $gi->get_items(0);
	my $ngu = $gu->get_items(0);
	
	# print number of sequences.
	#print NUMBER "$np\t$family\t$organism_dir\tprotein\n";
	#print NUMBER "$ng\t$family\t$organism_dir\tgene\n";
	open NUMBER, ">>number.txt" or die "$!";
	print NUMBER "$np_ls\t$family\t$organism_dir\tprotein_ls\n";
	print NUMBER "$np_fs\t$family\t$organism_dir\tprotein_fs\n";
	#print NUMBER "$ng_ls\t$family\t$organism_dir\tgene_ls\n";
	#print NUMBER "$ng_fs\t$family\t$organism_dir\tgene_fs\n";
	print NUMBER "$ngg_ls\t$family\t$organism_dir\tgene_ls-gw\n";
	print NUMBER "$ngg_fs\t$family\t$organism_dir\tgene_fs-gw\n";
	print NUMBER "$npu\t$family\t$organism_dir\tprotein union\n";
	print NUMBER "$npi\t$family\t$organism_dir\tprotein intersect\n";
	print NUMBER "$ngu\t$family\t$organism_dir\tgene union\n";
	print NUMBER "$ngi\t$family\t$organism_dir\tgene intersect\n";
	close NUMBER;
	
	# merge different lists.
	$lp_ls->merge($lp_fs);
	$lgg_ls->merge($lgg_fs);
	$lp_ls->merge($lgg_ls);

	# check exons (this should be done in just one file).
	$lp_ls->check_exons($eexons, $pos, 0);
	$lp_ls->print({file => "$base.txt"});
	
	# read sequence files.
	my $pro = new varDB::SeqIO({file => "$GENOMEDB/$organism_dir/protein.fa"});
	my $nuc = new varDB::SeqIO({file => "$GENOMEDB/$organism_dir/gene.fa"});
	
	# export in nelson's format.
	$param->chdir($info, 'nelson');
	$lp_ls->export_nelson({file => "$base-nelson.txt", info => $info,
						   protein => $pro, nucleotide => $nuc,
						   genome => $genome});
	
	# export FASTA file.
	$param->chdir($info, 'analysis');
	$lp_ls->export_fasta({file => "$base-protein.fa", db => $pro});
	$lp_ls->export_fasta({file => "$base-nucleotide.fa", db => $nuc});
}
