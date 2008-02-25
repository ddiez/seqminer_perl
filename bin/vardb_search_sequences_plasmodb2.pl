#!/usr/bin/env perl

use strict;
use warnings;

use varDB::Config;
use varDB::Position;

my $file = shift;

# define locations.
my $VARDB_RELEASE = 1;
my $OUTDIR = "$VARDB_HOME/families/vardb-$VARDB_RELEASE";
my $debug = 1;
if ($debug == 1) {
	my @time = localtime time;
	$time[5] += 1900;
	$time[4] ++;
	$time[4] = sprintf("%02d", $time[4]);
	$time[3] = sprintf("%02d", $time[3]);
	$time[2] = sprintf("%02d", $time[2]);
	$time[1] = sprintf("%02d", $time[1]);
	$time[0] = sprintf("%02d", $time[0]);

	$OUTDIR = "$VARDB_HOME/families/test/$time[5]$time[4]$time[3].$time[2]$time[1]$time[0]";
}

# create working directory, die on failure.
if (! -d $OUTDIR) {
	mkdir $OUTDIR;
} else {
	die "directory $OUTDIR already exists!.\n";
}

open IN, "$file" or die "$!";
while (<IN>) {
	# skip blank and comment lines.
	/^[#|\n]/ && do {
		next;
	};
	chomp;
	
	my ($super, $organism, $family, $seed, $pssm_eval, $psi_eval, $tbn_eval, $iter, $hmm_acc, $hmm_name, $hmm_eval, $eexons, $format) = split '\t', $_;
	
	my $base = undef; # defined in each search type.
	
	#print STDERR "searching for family $family in $organism ... ";

	# neither like this.
	my $outdir = "$OUTDIR/$super";
	if (! -d $outdir) {
		mkdir $outdir;
	}
	#$outdir .= "/$family-$organism";
	#mkdir $outdir;
	chdir $outdir;

	open NUMBER, ">>number.txt" or die "$!";
	#unlink "$family-number.txt";
	
	$base = "$family-$organism";
	###################################################
	## 1. do hmmer and find the best seed possible.

	# retrieve model with hmmfetch library hmm_name.
	# use libraries Pfam_ls and Pfam_fs.
	my $fs = $hmm_name."_ls";
	my $ls = $hmm_name."_fs";
	system "hmmfetch $HMMDB/$PFAM_VERSION/Pfam_ls $hmm_name > $fs.hmm";
	system "hmmfetch $HMMDB/$PFAM_VERSION/Pfam_fs $hmm_name > $ls.hmm";

	# search in protein genome.
	system "hmmsearch $ls.hmm $GENOMEDB/$organism/protein.fa > $base-protein\_ls.log";
	system "hmmsearch $fs.hmm $GENOMEDB/$organism/protein.fa > $base-protein\_fs.log";
	
	# parse results.
	system "hmmer_parse.pl -i $base-protein\_ls.log -e $hmm_eval > $base-protein\_ls.list";
	system "hmmer_parse.pl -i $base-protein\_fs.log -e $hmm_eval > $base-protein\_fs.list";
	
	# the best seed would be the best hit in the Pfam_ls search.
	# TODO: check that it is indeed a suitable seed (e-value/score).
	# if no suitable seed found, use the one provided in the config file.
	my $list = parse_list_file("$base-protein\_ls.list");
	$seed = $list->{gene_list}->[0];
	
	## 1.3 search with hmmsearch in gene-trans.
	system "hmmsearch $ls.hmm $GENOMEDB/$organism/gene-trans.fa > $base-gene\_ls.log";
	system "hmmsearch $fs.hmm $GENOMEDB/$organism/gene-trans.fa > $base-gene\_fs.log";
	
	# parse results.
	system "hmmer_parse.pl -i $base-gene\_ls.log -e $hmm_eval > $base-gene\_ls.list";
	system "hmmer_parse.pl -i $base-gene\_fs.log -e $hmm_eval > $base-gene\_fs.list";
	
	# TODO:
	# check for genes with multiple matches (with different offset/revcom) and
	# create an unified list for sequence retrieval? 
	
	###########################################################
	## 2. do psi-blast find best protein hits and get pssm.
	# get seed from hmmer search.
	my $seedfile = "$family-$organism.seed";
	system "extract_fasta.pl -d $seed -i $GENOMEDB/$organism/protein.idx > $seedfile";
	
	# search in protein database with psi-blast and generate pssm file.
	system "blastpgp -d $GENOMEDB/$organism/protein -i $seedfile -s T -j $iter -h $pssm_eval -C $base.chk -F T -b 10000  > $base.blastpgp";
	# write psi-blast report.
	system "psiblast_report.pl -i $base.blastpgp -e $pssm_eval > $base-cycles.txt";

	#####################################################
	## 3. do psitblastn and find best nuclotide hits.
	# search in nucleotide database with psitblastn.
	system "blastall -p psitblastn -d $GENOMEDB/$organism/gene -i $seedfile -R $base.chk -b 10000 > $base.psitblastn";
	
	####################################################################
	## 4. do QUALITY CHECK
	
	# get list of ids.
	system "blast_parse.pl -i $base.psitblastn -e $tbn_eval > $base-gene.list";
	system "blast_parse.pl -i $base.blastpgp -e $psi_eval > $base-protein.list";
	
	# read position file.
	my $pos = new varDB::Position({file => "$GENOMEDB/$organism/position.txt", format => $format});
	
	# read list file.
	my $np = check_exons("$base-protein.list", $eexons, $pos);
	my $ng = check_exons("$base-gene.list", $eexons, $pos);
	my $np_ls = check_exons("$base-protein_ls.list", $eexons, $pos);
	my $np_fs = check_exons("$base-protein_fs.list", $eexons, $pos);
	my $ng_ls = check_exons("$base-gene_ls.list", $eexons, $pos);
	my $ng_fs = check_exons("$base-gene_fs.list", $eexons, $pos);
	
	print STDERR << "OUT";
organism: $organism
family:   $family
np_ls:    $np_ls
np_fs:    $np_fs
ng_ls:    $ng_ls
ng_fs:    $ng_fs
np-psi:   $np
ng-psi:   $ng
OUT

	# print number of sequences.
	print NUMBER "$np\t$family\t$organism\tprotein\n";
	print NUMBER "$ng\t$family\t$organism\tgene\n";
	print NUMBER "$np_ls\t$family\t$organism\tprotein_ls\n";
	print NUMBER "$np_fs\t$family\t$organism\tprotein_fs\n";
	print NUMBER "$ng_ls\t$family\t$organism\tgene_ls\n";
	print NUMBER "$ng_fs\t$family\t$organism\tgene_fs\n";


	####################################################################
	##			
	# count number of sequences.
	# NOTE: TODO: if read list file do that here.
	#system "vardb_count_list.pl $base-nucleotide.list \"$family\t$organism\tnucleotide\" >> number.txt";
	#system "vardb_count_list.pl $base-protein.list \"$family\t$organism\tprotein\" >> number.txt";
	
	# get fasta files.
	system "extract_fasta.pl -f $base-gene.list -i $GENOMEDB/$organism/gene.idx > $base-gene.fa";
	system "extract_fasta.pl -f $base-protein.list -i $GENOMEDB/$organism/protein.idx > $base-protein.fa";

	close NUMBER;
	
	###################################################################
	## 5. compute some statistics and comparisons between the different
	##    sequences obtained with hmmer and psi-blast.
}
close IN;

sub parse_list_file {
	my $file = shift;
	open TMP, $file or die "ERROR [parse_list_file]: cannot open file $file: $!\n";
	
	my $gene = {};
	while (<TMP>) {
		chomp;
		my ($id, $score, $evalue) = split '\t', $_;
		if (! exists $gene->{gene}->{$id}) {
			$gene->{gene}->{$id}->{score} = $score;
			$gene->{gene}->{$id}->{evalue} = $evalue;
			push @{$gene->{gene_list}}, $id;
			$gene->{nseq}++;
		} else {
			print STDERR "WARNING [parse_list_file]: duplicated id $id\n";
		}
	}
	close TMP;
	
	return $gene;
}

sub check_exons {
	my $file = shift;
	my $eexons = shift;
	my $pos = shift;
	
	my $seqs = parse_list_file($file);
	my $nseqs = $seqs->{nseq};
	
	
	# quality check: check number of exons.
	open OUTLIST, ">$file";
	foreach my $id (@{$seqs->{gene_list}}) {
		# fix KEGG ids.
		#$id =~ /.+:(.+)/;
		#my $fixid = $1;
		#print STDERR ">$id#\t";
		my $nexons = $pos->get_nexon($id);
		print STDERR ">$nexons#\n";
		if ($nexons != $eexons) {
			if ($nexons == 1) {
				$seqs->{gene}->{$id}->{quality} = "putative pseudogene";
			} else {
				$seqs->{gene}->{$id}->{quality} = "incorrect exons";
			}
		} else { # good number of exons.
			$seqs->{gene}->{$id}->{quality} = "correct exons";
		}
		my $score = $seqs->{gene}->{$id}->{score};
		my $evalue = $seqs->{gene}->{$id}->{evalue};
		my $quality = $seqs->{gene}->{$id}->{quality};
		print OUTLIST "$id\t$score\t$evalue\t$eexons\t$nexons\t$quality\n";
	}
	close OUTLIST;
	return $nseqs;
}
