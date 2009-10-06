package SeqMiner::OrthologSet;

use strict;
use warnings;
use SeqMiner::Config;
use SeqMiner::Ortholog;
use SeqMiner::ItemSet;
use base "SeqMiner::ItemSet";

sub new {
	my $class = shift;
	my $self = $class->SUPER::new(@_);
	bless $self, $class;
    $self->_initialize(@_);
    return $self;
}

sub _initialize {
	my $self = shift;
	my $param = shift;

	if (defined $param->{empty}) {
		return if $param->{empty} == 1;
	}
	
	open IN, "$SM_ORTHOLOG_FILE" or die "$!";
	while (<IN>) {
		next if /^[#|\n]/;
		chomp;
		my ($id, $hmm) = split '\t', $_;
		my $ortholog = $self->get_item_by_id($id);
		if (! defined $ortholog) {
			$ortholog = new SeqMiner::Ortholog($_);
			$ortholog->id($id);
			$self->add($ortholog);
		}
		$ortholog->hmm($hmm);
	}
	close IN;
}

sub name {
	shift->id(@_);
}

sub ortholog_list {
	return shift->SUPER::item_list;
}

sub filter_by_ortholog_name {
	my $self = shift;
	my $filter = shift;
	return $self if $#{$filter} == -1;
	my $ts = new SeqMiner::OrthologSet({empty => 1});
	for my $taxon ($self->item_list) {
		for my $f (@{$filter}) {
			if ($taxon->name =~ /$f/) {
				$ts->add($taxon);
				last;
			}
		}
	}
	return $ts;
}

sub get_names_array {
	my $self = shift;
	my @a;
	for my $o ($self->item_list) {
		push @a, $o->name;
	}
	return @a;
}

sub update_hmm {
	my $self = shift;
	for my $o ($self->item_list) {
		$o->update_hmm;
	}
}

sub update_seed {
	my $self = shift;
	
	require SeqMiner::TaxonSet;
	my $ts = new SeqMiner::TaxonSet;
	$ts = $ts->filter_by_taxon_type(["spp"]);
	
	require SeqMiner::FamilySet;
	my $fs = new SeqMiner::FamilySet;
	
	require SeqMiner::SearchSet;
	my $ss = new SeqMiner::SearchSet;
	for my $f ($fs->item_list) {
		$ss->add({taxon => $ts->filter_by_taxon_name([$f->taxon]), ortholog => $self->filter_by_ortholog_name([$f->ortholog])});
	}
	$ss->debug;
	
	my $os_tmp = $self->filter_by_ortholog_name([$fs->get_ortholog_array]);
	for my $o ($os_tmp->item_list) {
		print STDERR "Ortholog: ", $o->name, "\n";
		my $ss_tmp = $ss->filter_by_ortholog_name([$o->name]);
		$ss_tmp->debug;
		my ($bh, $taxon) = $ss_tmp->get_best_hit;
		
		my $base = $o->name."-".$taxon->organism;
		my $dir = $taxon->organism;
		my $seed_file = "$SM_HOME/db/models/seed/".$o->name.".seed";
		my $pssm_file = "$SM_HOME/db/models/pssm/".$o->name.".chk";
		my $pgp_file = "$SM_HOME/db/models/pgp/".$o->name.".pgp";
		if (defined $bh) {
			my $seed = $bh->id;
			system "fastacmd -d $GENOMEDB/$dir/protein -s $seed -l 60 > $seed_file";
			print STDERR "* dir: $GENOMEDB/$dir\n";
			print STDERR "* seed: $seed\n";
			print STDERR "* seed file: $seed_file\n";
			print STDERR "* running PSI-BLAST search ... ";
			system "blastpgp -d $GENOMEDB/$dir/protein -i $seed_file -s T -j $PSSM_ITER -h $PSSM_EVALUE -C $pssm_file -F T -b 10000 -a 16 > $pgp_file";
			print STDERR "OK\n";
		}
	}
	
#	for my $o ($self->item_list) {
#		$o->update_seed;
#	}
}


sub debug {
	my $self = shift;
	print STDERR "#---", ref $self, "--->\n";
	print STDERR "* number of orthologs: ", $self->length, "\n";
	for my $o ($self->item_list) {
		print STDERR "* ", $o->name, "\t", $o->hmm, "\n";
	}
	print STDERR "\\\\\n";
}

1;
