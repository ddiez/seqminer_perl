package SeqMiner::SearchSet;

use strict;
use warnings;

#use SeqMiner::Config;
#use SeqMiner::OrthologSet;
#use SeqMiner::TaxonSet;
#use SeqMiner::PaperSet;
use SeqMiner::ItemSet;
use base "SeqMiner::ItemSet";

sub new {
	my $class = shift;
	my $self = $class->SUPER::new;
	bless $self, $class;
	$self->_initialize(@_);
    return $self;
}

sub _initialize {
	my $self = shift;
	my $param = shift;
	
	if (! defined $param) {
		require SeqMiner::SearchParameter;
		$self->{parameter} = new SeqMiner::SearchParameter;
	} elsif (ref $param eq "SeqMiner::SearchParameter") {
		$self->{parameter} = $param;
	}# else ignore.
#	my $param = shift;
	
#	if (defined $param->{empty}) {
#		return if $param->{empty} == 1;
#	}
	
#	my $ts = new SeqMiner::TaxonSet;
#	my $ps = new SeqMiner::PaperSet;
#	my $os = new SeqMiner::OrthologSet;
	
#	for my $ortholog ($os->item_list) {
#		for my $taxon ($ts->item_list) {
#			if ($taxon->ortholog->get_item_by_id($ortholog->id)) {
#				my $search = new SeqMiner::SearchSet::Search;
#				$search->id($taxon->type.".".$taxon->id.".".$ortholog->id.".".$taxon->family);
#				$search->search($taxon);
#				$search->family($ortholog);
#				$search->type($taxon->type);
#				$self->add($search);
#			}
#		}
		
#		for my $paper ($ps->item_list) {
#			if ($paper->ortholog->get_item_by_id($ortholog->id)) {
#				my $search = new SeqMiner::SearchSet::Search;
#				$search->id("paper.".$paper->id.".".$ortholog->id);
#				$search->search($paper);
#				$search->family($ortholog);
#				#$search->keywords($paper->keywords($ortholog->id));
#				$search->type('paper');
#				$self->add($search);
#			}
#		}
#	}
	
#	foreach my $taxon ($ts->item_list) {
#		#print STDERR "+ ", $taxon->id, "\n";
#		foreach my $family ($taxon->family->item_list) {
#			#print STDERR "  - ", $family->id, "\n";
#			my $search = new SeqMiner::SearchSet::Search($taxon, $family);
#			$search->id($search->taxon->id.".".$search->family->ortholog->id.".".$search->family->id);
#			$self->add($search);
#		}
#	}
}

sub parameter {
	my $self = shift;
	$self->{parameter} = shift if @_;
	return $self->{parameter};
}

sub add {
	my $self = shift;
	my $param = shift;
	
	if (ref $param eq "SeqMiner::SearchSet::Search") {
		$self->SUPER::add($param);
	} else {
		my $ts = $param->{taxon};
		my $os = $param->{ortholog};
	
		for my $taxon ($ts->item_list) {
			#if ($taxon->type eq "spp") {
				for my $ortholog ($os->item_list) {
					require SeqMiner::SearchSet::Search;
					my $search = new SeqMiner::SearchSet::Search;
					$search->id($taxon->type.".".$taxon->id.".".$ortholog->id);
					$search->taxon($taxon);
					$search->ortholog($ortholog);
					$search->source($taxon->type eq "spp" ? "genome" : "isolate");
					$self->SUPER::add($search);
				}
			#}
		}
	}
}

sub search {
	my $self = shift;
	for my $s ($self->item_list) {
		my $res = $s->search(@_);
		if ($res == -1) {
			die "ERROR: need to specify 'source' and 'type' parameters.\n";
		}
	}
}

sub filter_by_ortholog_name {
	my $self = shift;
	my $filter = shift;
	return $self if $#{$filter} == -1;
	my $ss = new SeqMiner::SearchSet;
	$ss->parameter($self->parameter);
	for my $s ($self->item_list) {
		for my $f (@{$filter}) {
			if ($s->ortholog->name =~ /$f/) {
				$ss->add($s);
				last;
			}
		}
	}
	return $ss;
}

sub get_best_hit {
	my $self = shift;
		
	my $bh = undef;
	my $taxon  = undef;
	print STDERR "##### BEST HIT #####\n";
	for my $s ($self->item_list) {
		#next if $s->source eq "isolate";
		$s->debug;
		$s->chdir("/tmp/");
		my $base = $s->ortholog->name."-".$s->taxon->organism;
		my @search_type = ("protein\_ls", "protein\_fs");
		require SeqMiner::ResultSet;
		my $cbh = undef;
		foreach my $search_type (@search_type) {
			my $rs = new SeqMiner::ResultSet({file => "$base-$search_type.log"});
			$cbh = $rs->get_result_by_pos(0)->best_hit;
			if (defined $cbh) {
				if (! defined $bh) {
					$bh = $cbh;
					$taxon = $s->taxon;
				} else {
					if ($cbh->significance < $bh->significance) {
						$bh = $cbh;
						$taxon = $s->taxon;
					}
				}
			}
		}
	}
	print STDERR "* best hit: ", $bh->id, " [", $bh->score, "/", $bh->significance, "]\n";
	print STDERR "* in species: ", $taxon->organism, "\n";
	
	return ($bh, $taxon);
}

sub debug {
	my $self = shift;
	print STDERR "#---", ref $self, "--->\n";
	print STDERR "* number of searches: ", $self->length, "\n";
	for my $s ($self->item_list) {
		print STDERR "* ", $s->taxon->name, ":", $s->ortholog->name, " [", $s->source, "]\n";
	}
	print STDERR "\\\\\n";
}

1;
