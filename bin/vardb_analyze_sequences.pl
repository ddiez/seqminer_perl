#!/usr/bin/env perl

use strict;
use warnings;

use varDB::Config;
use varDB::SearchIO;
use varDB::SeqIO;
use varDB::Genome;
use varDB::Position;
use varDB::ListIO;
use Sets;

my $file = shift;
$file = $VARDB_SEARCH_FILE if !defined $file;

print STDERR "reading config file: $file\n";

# define locations.
my $OUTDIR = "$VARDB_HOME/families/vardb-$VARDB_RELEASE";
my $DEBUG = 1;
if ($DEBUG == 1) {
	$OUTDIR = "$VARDB_HOME/families/test/last";
}
print STDERR "output_dir: $OUTDIR\n";

open IN, "$file" or die "$!";
while (<IN>) {
	next if /^[#|\n]/;
	chomp;
	
	my $info = new varDB::SearchIO($_);
	$info->debug;
	
	my $family = $info->get_family;
	my $organism_dir = $info->get_organism_dir;
	my $eexons = $info->get_eexons;
	my $base = "$family-$organism_dir";
	
	my $outdir = "$OUTDIR/".$info->get_super_family;
	chdir $outdir;

	open NUMBER, ">>number.txt" or die "$!";
	
	####################################################################
	## 4. do QUALITY CHECK
	
	# read position file.
	my $pos = new varDB::Position({file => "$GENOMEDB/$organism_dir/position.txt", format => $info->get_format});
	
	# read list file.
	my $lp = new varDB::ListIO({file => "$base-protein.list"});
	my $lg = new varDB::ListIO({file => "$base-gene.list"});
	my $lp_ls = new varDB::ListIO({file => "$base-protein_ls.list"});
	my $lp_fs = new varDB::ListIO({file => "$base-protein_fs.list"});
	my $lg_ls = new varDB::ListIO({file => "$base-gene_ls.list"});
	my $lg_fs = new varDB::ListIO({file => "$base-gene_fs.list"});
	
	my $np = $lp->get_number;
	my $ng = $lg->get_number;
	my $np_ls = $lp_ls->get_number;
	my $np_fs = $lp_fs->get_number;
	my $ng_ls = $lg_ls->get_number;
	my $ng_fs = $lg_fs->get_number;
	
	# compute sets stuff.
	my $pset = new Sets($lp->get_gene_list, $lp_ls->get_gene_list, $lp_fs->get_gene_list);
	my $gset = new Sets($lg->get_gene_list, $lg_ls->get_gene_list(1), $lg_ls->get_gene_list(1));
	
	my $pi = $pset->intersect;
	my $pu = $pset->union;
	my $npi = $pi->get_items(0);
	my $npu = $pu->get_items(0);
	
	my $gi = $gset->intersect;
	my $gu = $gset->union;
	my $ngi = $gi->get_items(0);
	my $ngu = $gu->get_items(0);
	
	print STDERR << "OUT";
np_ls:       $np_ls
np_fs:       $np_fs
ng_ls:       $ng_ls
ng_fs:       $ng_fs
np-psi:      $np
ng-psi:      $ng
p union:     $npu
p intersect: $npi
g union:     $ngu
g intersect: $ngi
OUT

	# print number of sequences.
	print NUMBER "$np\t$family\t$organism_dir\tprotein\n";
	print NUMBER "$ng\t$family\t$organism_dir\tgene\n";
	print NUMBER "$np_ls\t$family\t$organism_dir\tprotein_ls\n";
	print NUMBER "$np_fs\t$family\t$organism_dir\tprotein_fs\n";
	print NUMBER "$ng_ls\t$family\t$organism_dir\tgene_ls\n";
	print NUMBER "$ng_fs\t$family\t$organism_dir\tgene_fs\n";
	print NUMBER "$npu\t$family\t$organism_dir\tprotein union\n";
	print NUMBER "$npi\t$family\t$organism_dir\tprotein intersect\n";
	print NUMBER "$ngu\t$family\t$organism_dir\tgene union\n";
	print NUMBER "$ngi\t$family\t$organism_dir\tgene intersect\n";
	
	# check exons.
	$lp->check_exons($eexons, $pos, 0);
	$lg->check_exons($eexons, $pos, 0);
	$lp_ls->check_exons($eexons, $pos, 0);
	$lp_fs->check_exons($eexons, $pos, 0);
	$lg_ls->check_exons($eexons, $pos, 1);
	$lg_fs->check_exons($eexons, $pos, 1);
	
	$lp->print({file => "$base-foo.txt"});
	
	# read sequence files.
	my $pro = new varDB::SeqIO({file => "$GENOMEDB/$organism_dir/protein.fa"});
	my $nuc = new varDB::SeqIO({file => "$GENOMEDB/$organism_dir/gene.fa"});
	my $genome = new varDB::Genome({file => "$GENOMEDB/$organism_dir/genome.gff"});
	
	# export in nelson's format.
	$lp->export_nelson({file => "$base-nelson.txt", info => $info, protein => $pro, nucleotide => $nuc, genome => $genome});

	close NUMBER;
	
	system "extract_fasta.pl -f $base-gene.list -i $GENOMEDB/$organism_dir/gene.idx > $base-gene.fa";
	system "extract_fasta.pl -f $base-protein.list -i $GENOMEDB/$organism_dir/protein.idx > $base-protein.fa";
}
close IN;
