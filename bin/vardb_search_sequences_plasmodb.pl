#!/usr/bin/env perl

use strict;
use warnings;

use varDB::Config;
use varDB::Position;

my $file = shift;

# define locations.
my $OUTDIR = "$VARDB_HOME/families/test11";

# define search types.
my $search_genome = 1;
my $search_swprot = 0;
my $search_trembl = 0;
my $do_blast = 1;
my $do_hmmer = 0;
my $do_aln = 0;
my $do_tree = 0;

# i dont like this.
if (! -d $OUTDIR) {
	mkdir $OUTDIR;
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

	open NUMBER, ">number.txt" or die "$!";
	#unlink "$family-number.txt";

	# do psi-blast/blast.
	if ($do_blast) {
		# get seed sequence.
		my $seedfile = "$family-$organism.seed";
		system "extract_fasta.pl -d $seed -i $GENOMEDB/$organism/protein.idx > $seedfile";
	
		if ($search_genome) {
			$base = "$family-$organism";
			# search in protein database with psi-blast and generate pssm file.
			system "blastpgp -d $GENOMEDB/$organism/protein -i $seedfile -s T -j $iter -h $pssm_eval -C $base.chk -F T -b 10000  > $base.blastpgp";
			# write psi-blast report.
			system "psiblast_report.pl -i $base.blastpgp -e $pssm_eval > $base-cycles.txt";
		
			# search in nucleotide database with psitblastn.
			system "blastall -p psitblastn -d $GENOMEDB/$organism/gene -i $seedfile -R $base.chk -b 10000 > $base.psitblastn";
			
			####################################################################
			## QUALITY CHECK
			
			# get list of ids.
			system "blast_parse.pl -i $base.psitblastn -e $tbn_eval > $base-nucleotide.list";
			system "blast_parse.pl -i $base.blastpgp -e $psi_eval > $base-protein.list";
			
			# read position file.
			my $pos = new varDB::Position({file => "$GENOMEDB/$organism/position.txt", format => $format});
			
			# read list file.
			my $np = check_exons("$base-protein.list", $eexons, $pos);
			my $ng = check_exons("$base-nucleotide.list", $eexons, $pos);
			
			print "##$organism\n";
			print "##$family\n";
			print "##$np\n";
			print "##$np\n";
			
			# print number of sequences.
			print NUMBER "$np\t$family\t$organism\tprotein\n";
			print NUMBER "$ng\t$family\t$organism\tgene\n";

			####################################################################
			##			
			# count number of sequences.
			# NOTE: TODO: if read list file do that here.
			#system "vardb_count_list.pl $base-nucleotide.list \"$family\t$organism\tnucleotide\" >> number.txt";
			#system "vardb_count_list.pl $base-protein.list \"$family\t$organism\tprotein\" >> number.txt";
			
			# get fasta files.
			system "extract_fasta.pl -f $base-nucleotide.list -i $GENOMEDB/$organism/gene.idx > $base-nucleotide.fa";
			system "extract_fasta.pl -f $base-protein.list -i $GENOMEDB/$organism/protein.idx > $base-protein.fa";
			
			if ($do_aln) {
				# TODO.
			}
			
			if ($do_tree) {
				# TODO.
			}
		}
		
		if ($search_swprot) {
			$base = "$family-sprot";
			
			# search with psi-blast.
			system "blastpgp -d $UNIPROTDB/sprot -i $seedfile -s T -j $iter -h $pssm_eval -C $base.chk -F T -b 10000  > $base.blastpgp";
			
			# get list of ids.
			system "blast_parse.pl -i $base.blastpgp -e $psi_eval > $base.list";
			
			# count number of sequences.
			system "vardb_count_list.pl $base.list \"$family\t$organism\tswissprot\" >> $family-number.txt";
			
			if ($do_aln) {
			}
			
			if ($do_tree) {
			}
		}
		
		if ($search_trembl) {
			$base = "$family-trembl";
			
			# search with psi-blast.
			system "blastpgp -d $UNIPROTDB/trembl -i $seedfile -s T -j $iter -h $pssm_eval -C $base.chk -F T -b 10000  > $base.blastpgp";
			
			# get list of ids.
			system "blast_parse.pl -i $base.blastpgp -e $psi_eval > $base.list";
			
			# count number of sequences.
			system "vardb_count_list.pl $base.list \"$family\t$organism\ttrembl\" >> $family-number.txt";
			
			if ($do_aln) {
			}
			
			if ($do_tree) {
			}
		}
	}
	
	# do hmmer.
	if ($do_hmmer) {
		# retrieve model with hmmfetch library hmm_name.
		# use libraries Pfam_ls and Pfam_fs.
		
		# get models.
		my $fs = $hmm_name."_ls";
		my $ls = $hmm_name."_fs";
		system "hmmfetch $HMMDB/$PFAM_VERSION/Pfam_ls $hmm_name > $fs.hmm";
		system "hmmfetch $HMMDB/$PFAM_VERSION/Pfam_fs $hmm_name > $ls.hmm";
		
		if ($search_genome) {
			$base = "$family-$organism";
			# search in protein genome.
			system "hmmsearch $ls.hmm $GENOMEDB/$organism/protein.fa > $base\_ls.log";
			system "hmmsearch $fs.hmm $GENOMEDB/$organism/protein.fa > $base\_fs.log";
			
			# parse results.
			system "hmmer_parse.pl -i $base\_ls.log -e $hmm_eval > $base\_ls.list";
			system "hmmer_parse.pl -i $base\_fs.log -e $hmm_eval > $base\_fs.list";
			
			# count number of sequences.
			#system "vardb_count_list.pl $base\_ls.list \"$family\t$organism\thmm_ls\" >> $family-number.txt";
			#system "vardb_count_list.pl $base\_fs.list \"$family\t$organism\thmm_fs\" >> $family-number.txt";
			
			if ($do_aln) {
			}
			
			if ($do_tree) {
			}
		}
		
		# search swprot.
		if ($search_swprot) {
			$base = "$family-sprot";
			
			# search with ls and fs models.
			system "hmmsearch $ls.hmm $UNIPROTDB/uniprot_sprot.fasta > $base\_ls.log";
			system "hmmsearch $ls.hmm $UNIPROTDB/uniprot_sprot.fasta > $base\_fs.log";
			
			# parse results.
			system "hmmer_parse.pl -i $base\_ls.log -e $hmm_eval > $base\_ls.list";
			system "hmmer_parse.pl -i $base\_fs.log -e $hmm_eval > $base\_fs.list";
			
			if ($do_aln) {
			}
			
			if ($do_tree) {
			}
		}
		
		if ($search_trembl) {
			$base = "$family-trembl";
			
			# search with ls and fs models.
			system "hmmsearch $ls.hmm $UNIPROTDB/uniprot_trembl.fasta > $base\_ls.log";
			system "hmmsearch $ls.hmm $UNIPROTDB/uniprot_trembl.fasta > $base\_fs.log";
			
			# parse results.
			system "hmmer_parse.pl -i $base\_ls.log -e $hmm_eval > $base\_ls.list";
			system "hmmer_parse.pl -i $base\_fs.log -e $hmm_eval > $base\_fs.list";
			
			if ($do_aln) {
			}
			
			if ($do_tree) {
			}
		}
	}
	# combine/compare results from psi-blast and hmmer?

	#print STDERR "OK\n";
	close NUMBER;
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
		print STDERR ">$id#\t";
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
