package SeqMiner::SearchSet::Search;

=head1 MAIN

SeqMiner::SearchSet::Search;

Methods for performing search like operations like search using HMMER or PSI-Blast.

=cut


use strict;
use warnings;

use SeqMiner::Config;
use SeqMiner::ItemSet::Item;
use vars qw( @ISA );
@ISA = ("SeqMiner::ItemSet::Item");

sub new {
	my $class = shift;
	
	my $self = {};
	$self->{type} = undef;
	$self->{family} = undef;
	$self->{taxon} = undef;
	$self->{basedir} = undef;
	bless $self, $class;
    $self->_initialize(@_);
    return $self;
}

sub _initialize {
	my $self = shift;
	$self->{taxon} = shift if @_;
	$self->{family} = shift if @_;
	$self->{type} = $self->taxon->type;
	$self->_set_basedir;
}

sub _set_basedir {
	my $self = shift;
	my $basedir = "$SM_MINING_DIR/vardb-$SM_RELEASE/";
	$basedir = "$SM_MINING_DIR/last/" if $DEBUG == 1;
	if ($self->{type} eq "isolate") {
		$basedir .= "isolate";
	} else {
		$basedir .= "genome";
	}
	$self->{basedir} = $basedir;
}

sub basedir {
	return shift->{basedir};
}

sub family {
	my $self = shift;
	$self->{family} = shift if @_;
	return $self->{family};
}

sub type {
	my $self = shift;
	if (@_) {
		$self->{type} = shift;
		$self->_set_basedir;
	}
	return $self->{type};
}

sub taxon {
	my $self = shift;
	$self->{taxon} = shift if @_;
	return $self->{taxon};
}

sub search_sequence {
	my $self = shift;
	my $param = shift;
	
	my $res = undef;
	
	if ($self->{type} eq "isolate") {
		return 2 if ($param->{type} eq "genome");
		foreach my $db (values %TARGET_DB) {
			$res = $self->_search_isolate($db);
		}
	} else {
		return 2 if ($param->{type} eq "isolate");
		$res = $self->_search_genome;
	}

	return $res;
}

sub base {
	my $self = shift;
	return $self->family->name."-".$self->taxon->binomial;
}

sub _search_isolate {
	my $self = shift;
	my $tdb = shift;
	
	print STDERR "# SEARCH INFO\n";
	$self->debug;
		
	if ($self->chdir('search') == 0) {
		return 0;
	}
	
	my $base = $self->base;
	my $db = "$SM_HOME/db/isolate/".$self->taxon->name."/$tdb";
	
	if (-e "$db.gb") {
		my $pssm_file = "$SM_HOME/db/models/pssm/".$self->family->ortholog->id.".chk";
		my $seed_file = "$SM_HOME/db/models/seed/".$self->family->ortholog->id.".seed";
		my $evalue = 1e-02;
		
		print STDERR "+ db: $tdb\n";
		print STDERR "+ pssm: $pssm_file\n";
		print STDERR "+ seed: $seed_file\n";
		print STDERR "+ eval: $evalue\n\n";
		
		# run PSI-Blast.
		system "blastall -p psitblastn -d $db -i $seed_file -R $pssm_file -b 100000 > $base-$tdb.log";
		#system "blast_parse.pl -i $base.psitblastn -e $evalue > $base.list";
		
		# select sequences from original dataset.
		#&_select("$dir/isolate", "core.sel.list");
		
		# paper distribution.
		#&_paper_dist("$dir/isolate", "core.sel.gb", $taxon, "vsp");
	} else {
		print STDERR "* skip db $tdb (no data)\n\n";
	}
}

sub _search_genome {
	my $self = shift;
	
	print STDERR "# SEARCH INFO\n";
	$self->debug;
	
	if ($self->chdir('search') == 0) {
		return 0;
	}

	my $family = $self->family->name;
	my $dir = $self->taxon->dir;
	my $hmm_name = $self->family->hmm;
	my $iter = $PSSM_ITER;
	my $pssm_eval = $PSSM_EVALUE;
	my $base = $self->family->name."-".$self->taxon->dir;
	
	###################################################
	## 1. do hmm based search.

	# retrieve model with hmmfetch library hmm_name.
	# use libraries Pfam_ls and Pfam_fs.
	print STDERR "* fetching Pfam models ... ";
	if (! -d "$SM_HOME/db/models/hmm/ls/$hmm_name") {
		system "hmmfetch $SM_HOME/db/pfam/Pfam_ls.bin $hmm_name > $SM_HOME/db/models/hmm/ls/$hmm_name";
	}
	if (! -d "$SM_HOME/db/models/hmm/fs/$hmm_name") {
		system "hmmfetch $SM_HOME/db/pfam/Pfam_fs.bin $hmm_name > $SM_HOME/db/models/hmm/fs/$hmm_name";
	}
	my $ls = "$SM_HOME/db/models/hmm/ls/$hmm_name";
	my $fs = "$SM_HOME/db/models/hmm/fs/$hmm_name";
	print STDERR "OK\n";

	# search in protein sequences.
	print STDERR "* searching protein database (hmmer) ... ";
	system "hmmsearch $HMMERPARAM $ls $GENOMEDB/$dir/protein.fa > $base-protein\_ls.log";
	system "hmmsearch $HMMERPARAM $fs $GENOMEDB/$dir/protein.fa > $base-protein\_fs.log";
	print STDERR "OK\n";
	
	# search in nucleotide sequences.
	#
	# From the Wise2 documentation.
	# Scores
	#
	# The scoring system for the algorithms, as eluded to earlier is a 
	# Bayesian score. This score is related to the probability that model 
	# provided in the algorithm exists in the sequence (often called the 
	# posterior). Rather than expressing this probability directly I report 
	# a log-odds ratio of the likelihood of the model compared to a random model 
	# of DNA sequence. This ratio (often called bits score because the log is 
	# base 2) should be such that a score of 0 means that the two 
	# alternatives it has this homology and it is a random DNA sequence are 
	# equally likely. However there are two features of the scoring scheme that 
	# are not worked into the score that means that some extra calculations are 
	# required
	# The score is reported as a likelihood of the models, and to convert this 
	# to a posterior probability you need to factor in the ratio of the prior 
	# probabilities for a match. Because you expect a far greater number of 
	# sequences to be random than not, this probability of your prior knowledge 
	# needs to be worked in. Offhand sensible priors would in the order of 
	# probability that there is a match being roughly proportional to the 
	# database size.
	# The posterior probability should not merely be in favour of the homology 
	# model over the random model but also be confident in it. In other words you 
	# would want probabilities in the 0.95 or 0.99 range before being confident 
	# that this match was correct.
	# These two features mean that the reported bits score needs to be above 
	# some threshold which combines the effect of the prior probabilities and the 
	# need to have confidence in the posterior probability. In this field people 
	# do not tend to work the threshold out rigorously using the above technique, 
	# as in fact, deficiencies in the model mean that you end up choosing some 
	# arbitary number for a cutoff. In my experience, the following things hold 
	# true: bit scores above 35 nearly always mean that there is something there, 
	# bit scores between 25-35 generally are true, and bit scores between 18-25 
	# in some families are true but in other families definitely noise. I don't 
	# trust anything with a bit score less than 15 bits for these DNA based 
	# searches. For protein-HMM to protein there are a number of cases where very 
	# negative bit scores are still 'real' (this is best shown by a classical 
	# statistical method, usually given as e-values, which is available from the 
	# HMMer2 package), but this doesn't seem to occur in the DNA searches.
	# I have been thinking about using a classical statistic method on top of 
	# the bit score, assuming the distribution is an extreme value distribution 
	# (EVD), but for DNA it becomes difficult to know what to do with the problem 
	# of different lengths of DNA. As these can be wildly different, it is hard 
	# to know precisely how to handle it. Currently a single HMM compared to a 
	# DNA database can produce e-values using Sean Eddy's EVD fitting code but, I 
	# am not completely confident that I am doing the correct thing. Please use 
	# it, but keep in mind that it is an experimental feature.
	#
	print STDERR "* searching nucleotide database (genewisedb) ... ";
	system "genewisedb $WISEPARAM -hmmer $ls $GENOMEDB/$dir/gene.fa > $base-gene\_ls.log";
	system "genewisedb $WISEPARAM -hmmer $fs $GENOMEDB/$dir/gene.fa > $base-gene\_fs.log";
	print STDERR "OK\n";
	
	###########################################################
	## 2. do psi-blast find best protein hits and get pssm.
	
	# the seed would be the best hit in the Pfam_ls search, but if
	# there is nothing there, then the next one will be tested.
	# if no suitable seed found, use the one provided in the config file.
	#my @search_type = ("protein\_ls", "protein\_fs", "gene\_ls", "gene\_fs");
	#use SeqMiner::ResultSet;
	#
	#my $bh = undef;
	#foreach my $search_type (@search_type) {
	#	my $rs = new SeqMiner::ResultSet({file => "$base-$search_type.log"});
	#	$bh = $rs->get_result_by_pos(0)->best_hit;
	#	last if defined $bh
	#}
	#
	#if (defined $bh) {
	#	my $seed = $bh->id;
	#
	#	my $seedfile = "$family-$dir.seed";
	#	system "extract_fasta.pl -d $seed -i $GENOMEDB/$dir/protein.idx > $seedfile";
	#	
	#	# search in protein database with psi-blast and generate pssm file.
	#	print STDERR "* searching protein database (psi-blast) ... ";
	#	system "blastpgp -d $GENOMEDB/$dir/protein -i $seedfile -s T -j $iter -h $pssm_eval -C $base.chk -F T -b 10000  > $base.blastpgp";
	#	print STDERR "OK\n";
	#	# write psi-blast report.
	#	system "psiblast_report.pl -i $base.blastpgp -e $pssm_eval > $base-cycles.txt";
	#
	#	# search in nucleotide database with psitblastn.
	#	print STDERR "* searching nucleotide database (psitblastn) ... ";
	#	system "blastall -p psitblastn -d $GENOMEDB/$dir/gene -i $seedfile -R $base.chk -b 10000 > $base.psitblastn";
	#	print STDERR "OK\n";
	#} else {
	#	print STDERR "* no best hit found - skipping psi-blast search.\n";
	#}
	
	print STDERR "\n";
	
	return 1;
}

sub seed {
	my $self = shift;
	
	$self->debug;
	if ($self->chdir('search') == 0) {
		return 0;
	}
	
	my $base = $self->family->name."-".$self->taxon->dir;
	my $dir = $self->taxon->dir;
	my $seed_file = "$SM_HOME/db/models/seed/".$self->family->ortholog->id.".seed";
	my $pssm_file = "$SM_HOME/db/models/pssm/".$self->family->ortholog->id.".chk";
	my $pgp_file = "$SM_HOME/db/models/pgp/".$self->family->ortholog->id.".pgp";
	my @search_type = ("protein\_ls", "protein\_fs", "gene\_ls", "gene\_fs");
	
	use SeqMiner::ResultSet;
	my $bh = undef;
	foreach my $search_type (@search_type) {
		my $rs = new SeqMiner::ResultSet({file => "$base-$search_type.log"});
		$bh = $rs->get_result_by_pos(0)->best_hit;
		last if defined $bh
	}
	
	if (defined $bh) {
		my $seed = $bh->id;
		#system "extract_fasta.pl -d $seed -i $GENOMEDB/$dir/protein.idx > $seed_file";
		system "fastacmd -d $GENOMEDB/$dir/protein -s $seed > $seed_file";
		system "blastpgp -d $GENOMEDB/$dir/protein -i $seed_file -s T -j $PSSM_ITER -h $PSSM_EVALUE -C $pssm_file -F T -b 10000  > $pgp_file";
	}
	
	return 1;
}

sub hmm {
	my $self = shift;
	
	$self->debug;
	my $hmm_name = $self->family->hmm;
	
	print STDERR "* fetching Pfam models ... ";
	system "hmmfetch $SM_HOME/db/pfam/Pfam_ls.bin $hmm_name > $SM_HOME/db/models/hmm/ls/$hmm_name";
	system "hmmfetch $SM_HOME/db/pfam/Pfam_fs.bin $hmm_name > $SM_HOME/db/models/hmm/fs/$hmm_name";
	print STDERR "OK\n";
}

sub analyze_sequence {
	my $self = shift;
	my $param = shift;
	
	print STDERR "# ANALYZE SEQUENCE\n";
	$self->debug;
	
	my $res = undef;
	if ($self->{type} eq "isolate") {
		return 2 if ($param->{type} eq "genome");
		foreach my $db (values %TARGET_DB) {
			$res = $self->_analyze_isolate($db);
		}
	} else {
		return 2 if ($param->{type} eq "isolate");
		$res = $self->_analyze_genome;
	}
	return $res;
}

sub _analyze_isolate {
	my $self = shift;
	my $tdb = shift;

	my $family = $self->family->name;
	my $dir = $self->taxon->dir;
	my $db = "$SM_HOME/db/isolate/".$self->taxon->name."/$tdb";
	my $hmm_name = $self->family->hmm;
	my $iter = $PSSM_ITER;
	my $pssm_eval = $PSSM_EVALUE;
	my $base = $self->family->name."-".$self->taxon->binomial;

	$self->chdir('search');
	if (-e "$base-$tdb.log") {
		use SeqMiner::ResultSet;	
		my $rs = new SeqMiner::ResultSet({file => "$base-$tdb.log", id => "$tdb"});
		my $r = $rs->get_result_by_id($tdb);
		
		$self->chdir('fasta') or die "cannot change to directory 'fasta'";
		use SeqMiner::SeqSet;
		my $seq = new SeqMiner::SeqSet({file => "$db.fa"});
		$r->export_fasta({file => "$base-$tdb.fa", db => $seq});
		
		$self->chdir('sequences');
		$r->export_nelson_for_isolate({file => "$base-$tdb.txt", search => $self,
			sequence => $seq});
	}
	return 1;
}

sub _analyze_genome {
	my $self = shift;
	
	#return 1;
	my $family = $self->family->name;
	my $dir = $self->taxon->dir;
	my $hmm_name = $self->family->hmm;
	my $iter = $PSSM_ITER;
	my $pssm_eval = $PSSM_EVALUE;
	my $base = $self->family->name."-".$self->taxon->dir;
	
	# get genome info.
	use SeqMiner::Genome;
	my $genome = new SeqMiner::Genome({file => "$GENOMEDB/$dir/genome.gff"});

	# read result files.
	$self->chdir('search');
	use SeqMiner::ResultSet;
	my $rs = new SeqMiner::ResultSet({file => "$base-protein_ls.log", id => 'protein_ls', model_type => 'ls'});
	$rs->add({file => "$base-protein_fs.log", id => 'protein_fs', model_type => 'fs'});
	$rs->add({file => "$base-gene_ls.log", id => 'gene_ls', model_type => 'ls'});
	$rs->add({file => "$base-gene_fs.log", id => 'gene_fs', model_type => 'fs'});
	
	my $p_ls = $rs->get_result_by_id('protein_ls');
	my $p_fs = $rs->get_result_by_id('protein_fs');
	my $g_ls = $rs->get_result_by_id('gene_ls');
	my $g_fs = $rs->get_result_by_id('gene_fs');
	
	my $np_ls = $p_ls->length;
	my $np_fs = $p_fs->length;
	my $ngg_ls = $g_ls->length;
	my $ngg_fs = $g_fs->length;
	
	use Sets;
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
	use SeqMiner::SeqSet;
	my $pro = new SeqMiner::SeqSet({file => "$GENOMEDB/$dir/protein.fa"});
	my $nuc = new SeqMiner::SeqSet({file => "$GENOMEDB/$dir/gene.fa"});
	
	# export in nelson's format.
	$self->chdir('sequences') or die "cannot change to directory 'sequences'";
	$p_ls->export_nelson({file => "$base.txt", search => $self,
						   protein => $pro, nucleotide => $nuc,
						   genome => $genome});
	
	# export FASTA file.
	$self->chdir('fasta') or die "cannot change to directory 'fasta'";
	$p_ls->export_fasta({file => "$base-protein.fa", db => $pro});
	$p_ls->export_fasta({file => "$base-nucleotide.fa", db => $nuc});
}

sub search_domain {
	my $self = shift;
	my $param = shift;

	print STDERR "# SEARCH DOMAIN\n";
	$self->debug;
	
	my $res = undef;
	if ($self->{type} eq "isolate") {
		return 2 if ($param->{type} eq "genome");
		foreach my $db (values %TARGET_DB) {
			$res = $self->_search_pfam_isolate($db);
		}
	} else {
		return 2 if ($param->{type} eq "isolate");
		$res = $self->_search_pfam_genome;
	}
	
	return $res;
}

sub _search_pfam_genome {
	my $self = shift;
	
	use SeqMiner::Hmmer::Hmmpfam;
	my $hmmer = new SeqMiner::Hmmer::Hmmpfam;
	
	$self->chdir('fasta');
	
	# first we do protein sequences:
	my $base = $self->family->name."-".$self->taxon->dir."-protein";
	
	$hmmer->infile($base.".fa");
	$hmmer->outdir($self->dir('pfam'));
	
	$hmmer->outfile($base."_ls.log");
	$hmmer->model("$SM_HOME/db/pfam/Pfam_ls.bin");
	$hmmer->run;
	
	$hmmer->outfile($base."_fs.log");
	$hmmer->model("$SM_HOME/db/pfam/Pfam_fs.bin");
	$hmmer->run;
}

sub _search_pfam_isolate {
	my $self = shift;
	
	#print STDERR "## NOT YET IMPLEMENTED\n";
}

sub analyze_domain {
	my $self = shift;
	my $param = shift;
	
	print STDERR "# ANALYZE DOMAIN\n";
	$self->debug;
	
	my $res = undef;
	if ($self->{type} eq "isolate") {
		return 2 if ($param->{type} eq "genome");
		foreach my $db (values %TARGET_DB) {
			$res = $self->_analyze_pfam_isolate($db);
		}
	} else {
		return 2 if ($param->{type} eq "isolate");
		$res = $self->_analyze_pfam_genome;
	}
	return $res;
}

sub _analyze_pfam_genome {
	my $self = shift;
	
	$self->chdir('pfam');

	# first we do protein sequences:
	#my $base = $self->family->name."-".$self->taxon->dir."-protein";
	my $base = $self->family->name."-".$self->taxon->dir;
	my $ls = new SeqMiner::ResultSet({file => "$base-protein\_ls.log", id => 'protein_ls', model_type => 'ls'});
	my $fs = new SeqMiner::ResultSet({file => "$base-protein\_fs.log", id => 'protein_fs', model_type => 'ls'});

	$self->chdir('domains');
	SeqMiner::ResultSet::export_pfam({file => "$base-pfam.txt", fs => $fs, ls => $ls});
}

sub _analyze_pfam_isolate {
	my $self = shift;
	
	#print STDERR "## NOT YET IMPLEMENTED\n";
}

sub chdir {
	my $self = shift;
	my $dir = shift;
	
	my $outdir = "$self->{basedir}/$dir/".$self->family->ortholog->id;
	
	my $res = chdir $outdir;
	return $res;
}

sub dir {
	my $self = shift;
	my $dir = shift;
	
	return "$self->{basedir}/$dir/".$self->family->ortholog->id;
}


sub debug {
	my $self = shift;
	
	print STDERR "* id: ", $self->id, "\n";
	print STDERR "* organism: ", $self->taxon->organism, "\n";
	print STDERR "* taxon: [", $self->taxon->id, "] ", $self->taxon->name, "\n";
	print STDERR "* ortholog: ", $self->family->ortholog->id, "\n";
	print STDERR "* family: ", $self->family->name, "\n";
	print STDERR "* hmm: ", $self->family->hmm, "\n";
	print STDERR "* type: ", $self->type, "\n";
	print STDERR "* base_dir: $self->{basedir}\n";
	print STDERR "\n";
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

sub commit {
	my $self = shift;
	
	my $base = $self->family->name."-".$self->taxon->dir;
	$self->chdir("sequences");
	
	my $file = undef;
	if ($self->type eq "genome") {
		$file = $base.".txt";
		$self->commit_file($file, "sequences");
	} else {
		$file = $base."-core.txt";
		$self->commit_file($file, "sequences");
		$file = $base."-est.txt";
		$self->commit_file($file, "sequences");
	}
	
	$self->chdir("domains");
	if ($self->type eq "genome") {
		$file = $base."-pfam.txt";
		$self->commit_file($file, "pfam");
	} else {
		#$file = $base."-core.txt";
		#$self->commit_file($file);
		#$file = $base."-est.txt";
		#$self->commit_file($file);
	}
}


sub commit_file {
	my $self = shift;
	my $file = shift;
	my $dir = shift;

	my $outdir = $SM_COMMIT_DIR.$dir."/".$self->family->ortholog->id;
	
	print STDERR "* commiting $file ... ";
	if (-e $file) {
		my $res = system "cp", $file, $outdir;
		die "ERROR [commit]: some error occured commiting files: $!" if $res == -1;
		print STDERR "OK\n";
	} else {
		print STDERR "ERROR [$!]\n";
	}	
}

1;