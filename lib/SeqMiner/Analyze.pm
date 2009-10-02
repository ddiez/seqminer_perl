package SeqMiner::Analyze;

use strict;
use warnings;

use SeqMiner::Config;
use SeqMiner::ItemSet::Item;
use base "SeqMiner::ItemSet::Item";

sub new {
	my $class = shift;
	my $self = $class->SUPER::new(@_);
	bless $self, $class;
    $self->_initialize(@_);
    return $self;
}

sub _initialize {
	my $self = shift;
}

sub analyze {
	my $self = shift;
	my $param = shift;
	
	my $res = undef;
	if ($param->{source} eq "genome") {
		return 2 if ($self->source eq "isolate");
		if ($param->{type} eq "domain") {
			$res = $self->_analyze_domain_genome;
		}
	} elsif($param->{source} eq "isolate") {
		return 2 if ($param->{type} eq "genome");
		foreach my $db (values %TARGET_DB) {
			if ($param->{type} eq "domain") {
				$res = $self->_analyze_domain_isolate($db);
			}
		}
	}
	
	return $res;
}

#sub analyze_domain {
#	my $self = shift;
#	my $param = shift;
#	
#	print STDERR "# ANALYZE DOMAIN\n";
#	$self->debug;
#	
#	my $res = undef;
#	if ($self->source eq "isolate") {
#		return 2 if ($param->{type} eq "genome");
#		foreach my $db (values %TARGET_DB) {
#			$res = $self->_analyze_pfam_isolate($db);
#		}
#	} else {
#		return 2 if ($param->{type} eq "isolate");
#		$res = $self->_analyze_pfam_genome;
#	}
#	return $res;
#}
#
#sub analyze_sequence {
#	my $self = shift;
#	my $param = shift;
#	
#	print STDERR "# ANALYZE SEQUENCE\n";
#	$self->debug;
#	
#	my $res = undef;
#	if ($self->source eq "isolate") {
#		return 2 if ($param->{type} eq "genome");
#		foreach my $db (values %TARGET_DB) {
#			$res = $self->_analyze_isolate($db);
#		}
#	} else {
#		return 2 if ($param->{type} eq "isolate");
#		$res = $self->_analyze_genome;
#	}
#	return $res;
#}

#sub _analyze_sequence_isolate {
#	my $self = shift;
#	my $tdb = shift;
#
#	my $family = $self->family->name;
#	my $dir = $self->taxon->dir;
#	my $db = "$SM_HOME/db/isolate/".$self->taxon->name."/$tdb";
#	my $hmm_name = $self->family->hmm;
#	my $iter = $PSSM_ITER;
#	my $pssm_eval = $PSSM_EVALUE;
#	my $base = $self->family->name."-".$self->taxon->binomial;
#
#	$self->chdir('search');
#	if (-e "$base-$tdb.log") {
#		use SeqMiner::ResultSet;	
#		my $rs = new SeqMiner::ResultSet({file => "$base-$tdb.log", id => "$tdb"});
#		my $r = $rs->get_result_by_id($tdb);
#		
#		$self->chdir('fasta') or die "cannot change to directory 'fasta'";
#		use SeqMiner::SeqSet;
#		my $seq = new SeqMiner::SeqSet({file => "$db.fa"});
#		$r->export_fasta({file => "$base-$tdb.fa", db => $seq});
#		
#		$self->chdir('sequences');
#		$r->export_nelson_for_isolate({file => "$base-$tdb.txt", search => $self,
#			sequence => $seq});
#	}
#	return 1;
#}

#sub _analyze_sequence_genome {
#	my $self = shift;
#	
#	#return 1;
#	my $family = $self->family->name;
#	my $dir = $self->taxon->dir;
#	my $hmm_name = $self->family->hmm;
#	my $iter = $PSSM_ITER;
#	my $pssm_eval = $PSSM_EVALUE;
#	my $base = $self->family->name."-".$self->taxon->dir;
#	
#	# get genome info.
#	use SeqMiner::Genome;
#	my $genome = new SeqMiner::Genome({file => "$GENOMEDB/$dir/genome.gff"});
#
#	# read result files.
#	$self->chdir('search');
#	use SeqMiner::ResultSet;
#	my $rs = new SeqMiner::ResultSet({file => "$base-protein_ls.log", id => 'protein_ls', model_type => 'ls'});
#	$rs->add({file => "$base-protein_fs.log", id => 'protein_fs', model_type => 'fs'});
#	$rs->add({file => "$base-gene_ls.log", id => 'gene_ls', model_type => 'ls'});
#	$rs->add({file => "$base-gene_fs.log", id => 'gene_fs', model_type => 'fs'});
#	
#	my $p_ls = $rs->get_result_by_id('protein_ls');
#	my $p_fs = $rs->get_result_by_id('protein_fs');
#	my $g_ls = $rs->get_result_by_id('gene_ls');
#	my $g_fs = $rs->get_result_by_id('gene_fs');
#	
#	my $np_ls = $p_ls->length;
#	my $np_fs = $p_fs->length;
#	my $ngg_ls = $g_ls->length;
#	my $ngg_fs = $g_fs->length;
#	
#	use Sets;
#	my $pset = new Sets($p_ls->hit_ids, $p_fs->hit_ids);
#	my $gset = new Sets($g_ls->hit_ids, $g_fs->hit_ids);
#	
#	my $pi = $pset->intersect;
#	my $pu = $pset->union;
#	my $npi = $pi->get_items(0);
#	my $npu = $pu->get_items(0);
#	
#	my $gi = $gset->intersect;
#	my $gu = $gset->union;
#	my $ngi = $gi->get_items(0);
#	my $ngu = $gu->get_items(0);
#	
#	# print number of sequences.
#	#$param->chdir($info, 'analysis');
#	#$rs->export_number({file => "$base-number.txt"});
#	# deprecated.
#	#open NUMBER, ">>number.txt" or die "$!";
#	#print NUMBER "$np_ls\t$family\t$organism_dir\tprotein_ls\n";
#	#print NUMBER "$np_fs\t$family\t$organism_dir\tprotein_fs\n";
#	#print NUMBER "$ngg_ls\t$family\t$organism_dir\tgene_ls-gw\n";
#	#print NUMBER "$ngg_fs\t$family\t$organism_dir\tgene_fs-gw\n";
#	#print NUMBER "$npu\t$family\t$organism_dir\tprotein union\n";
#	#print NUMBER "$npi\t$family\t$organism_dir\tprotein intersect\n";
#	#print NUMBER "$ngu\t$family\t$organism_dir\tgene union\n";
#	#print NUMBER "$ngi\t$family\t$organism_dir\tgene intersect\n";
#	#close NUMBER;
#	
#	# merge different results.
#	$p_ls->merge($p_fs);
#	$g_ls->merge($g_fs);
#	$p_ls->merge($g_ls);
#	
#	# read sequence files.
#	use SeqMiner::SeqSet;
#	my $pro = new SeqMiner::SeqSet({file => "$GENOMEDB/$dir/protein.fa"});
#	my $nuc = new SeqMiner::SeqSet({file => "$GENOMEDB/$dir/gene.fa"});
#	
#	# export in nelson's format.
#	$self->chdir('sequences') or die "cannot change to directory 'sequences'";
#	$p_ls->export_nelson({file => "$base.txt", search => $self,
#						   protein => $pro, nucleotide => $nuc,
#						   genome => $genome});
#	
#	# export FASTA file.
#	$self->chdir('fasta') or die "cannot change to directory 'fasta'";
#	$p_ls->export_fasta({file => "$base-protein.fa", db => $pro});
#	$p_ls->export_fasta({file => "$base-nucleotide.fa", db => $nuc});
#}

sub _parse_domain_genome {
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

sub _parse_domain_isolate {
	my $self = shift;
	
	#print STDERR "## NOT YET IMPLEMENTED\n";
}

1;