package varDB::ResultSet::Result;
###### SUMMARY:
# this class store a single search report from a hmmer/genewise search.
# a search report is the output of:
#  - a search of a sequence agains a library of HMM models.
#  - a search of a model agains a sequence database.
# a result contains the query sequence/hmm and one or several hits of that
# search (domains/sequences). it also contains the scores, significance and
# locations of the hits in the sequences.
# each result also track the program used to generate it and the parameters.
use strict;
use warnings;

use varDB::ResultSet::Hit;
use varDB::TaxonSet;

sub new {
	my $class = shift;
	
	my $self = {};
	$self->{id} = undef;
	$self->{method} = undef;
	$self->{model} = undef;
	$self->{cutoff} = 1e-02;
	$self->{nhit} = 0;
	$self->{hit_list} = [];
	
	bless $self, $class;
    $self->_initialize(@_) if @_;
    return $self;
}

sub _initialize {
	my $self = shift;
	my $param = shift;
	# NOTE: nothing here yet.
}

# number of hits in the result.
sub length {
	return shift->{nhit};
}

# id of this result.
sub id {
	my $self = shift;
	$self->{id} = shift if @_;
	return $self->{id};
}

sub cutoff {
	my $self = shift;
	$self->{cutoff} = shift if @_;
	return $self->{cutoff};
}


# method used for the search, may be hmmpfam, hmmsearch, genewise.
sub method {
	my $self = shift;
	$self->{method} = shift if @_;
	return $self->{method};
}

# model used for the search.
sub model {
	my $self = shift;
	$self->{model} = shift if @_;
	return $self->{model};
}

# returns an array of hit objects.
sub hit_list {
	return @{ shift->{hit_list} };
}

# return an array of hit names.
sub hit_ids {
	my $self = shift;
	my @hit_ids;
	foreach my $hit ($self->hit_list) {
		push @hit_ids, $hit->id;
	}
	return \@hit_ids;
}

sub add_hit {
	my $self = shift;
	my $hit = shift;
	push @{$self->{hit_list}}, $hit;
	$self->{nhit}++;
}

sub get_hit {
	my $self = shift;
	my $n = shift;
	return undef if $n > $self->length;
	return $self->{hit_list}->[$n];
}

sub get_hit_by_id {
	my $self = shift;
	my $id = shift;
	foreach my $hit ($self->hit_list) {
		if ($hit->id eq $id) {
			return $hit;
		}
	}
	return undef;
}

sub has_hit {
	my $self = shift;
	my $hit = shift;
	foreach my $hit_ ($self->hit_list) {
		if ($hit_->id eq $hit->id) {
			return 1;
		}
	}
	return 0;
}

sub best_hit {
	my $self = shift;
	my $evalue = undef;
	my $best_hit = undef;
	foreach my $hit ($self->hit_list) {
		if (!defined $best_hit) {
			$evalue = $hit->significance;
			$best_hit = $hit;
		}
		if ($hit->significance <= $evalue) {
			$evalue = $hit->significance ;
			$best_hit = $hit;
		}
	}
	return $best_hit;
}

sub merge {
	my $self = shift;
	my $res = shift;
	foreach my $hit ($res->hit_list) {
		if (!$self->has_hit($hit)) {
			$self->add_hit($hit);
		}
	}
}

sub export_nelson_for_isolate {
	my $self = shift;
	my $param = shift;
	
	my $fh = *STDOUT;
	if ($param->{file}) {
		open OUT, ">$param->{file}" or die "[ResultSet::Result::export_nelson] cannot open file $param->{file} for writing: $!\n";
		$fh = *OUT;
	}
	
	my $seq = $param->{sequence};
	
	# parse and fix information.
	my $search = $param->{search};
	my $taxon = $search->taxon;
	my $organism = $taxon->organism;
	#my $strain = $taxon->strain;
	
	my $org_id = $organism;
	my $org_tax = $organism. ".".$taxon->id;
	
	print $fh "SEQUENCE", "\t",
		"family", "\t",
		"genome", "\t",
		#"strain", "\t",
		#"chromosome", "\t",
		#"translation", "\t",
		"sequence", "\t",
		#"start", "\t",
		#"end", "\t",
		#"strand", "\t",
		#"numexons", "\t",
		#"splicing", "\t",
		#"pseudogene", "\t",
		#"truncated", "\t",
		#"rating", "\t",
		"method", "\t",
		#"model", "\t",
		"score", "\t",
		"evalue", "\t",
		#"hmmloc", "\t",
		"description", "\n";
	
	my %hit_unique;
	my @hit_unique;
	foreach my $hit ($self->hit_list) {
		my $id = $hit->id;
		push @hit_unique, $id if ! exists $hit_unique{$id};
		push @{ $hit_unique{$id} }, $hit;
	}
	
	foreach my $id (@hit_unique) {
		my @hit = @{ $hit_unique{$id} };
		### TODO: fix this !!!!
		#!!!!!!!!!!!!!!!!!!!!!!
		my $hit = $hit[0];
		#!!!!!!!!!!!!!!!!!!!!!!
		
		my $nuc_seq = $seq->get_seq_by_id($id);
		if (defined $nuc_seq) {
			$nuc_seq = $nuc_seq->seq;
		} else {
			$nuc_seq = "";
		}
		
		my $hmmloc = "";
		my @hmmloc;
		foreach my $hit_ (@hit) {
			push @hmmloc, join "..", $hit_->start, $hit_->end if defined $hit_->start and defined $hit_->end;
		}
		$hmmloc = join ",", @hmmloc;
		
		print $fh
			"$id\t",
			$organism.".".$search->family->id, "\t",
			$org_tax, "\t",
		#	$taxon->strain, "\t",
		#	$org_tax.".".$gene->chromosome, "\t",
		#	$pro_seq, "\t",
			$nuc_seq, "\t",
		#	$gene->start, "\t",
		#	$gene->end, "\t",
		#	$gene->strand eq "+" ? "forward" : "reverse", "\t",
		#	$gene->nexons, "\t",
		#	$exonloc, "\t",
		#	$gene->pseudogene ? "TRUE" : "FALSE", "\t",
		#	"FALSE", "\t",
		#	$gene->quality($eexons), "\t",
			$hit->method, "\t",
		#	$search->family->hmm, "\t",
			$hit->score, "\t",
			$hit->significance, "\t",
			$hmmloc, "\t",
			"", "\n";
	}
	
	
}

sub export_nelson {
	my $self = shift;
	my $param = shift;
	
	my $fh = *STDOUT;
	if ($param->{file}) {
		open OUT, ">$param->{file}" or die "[ResultSet::Result::export_nelson] cannot open file $param->{file} for writing: $!\n";
		$fh = *OUT;
	}
	
	#my $ts = new varDB::TaxonSet;
	
	my $pro = $param->{protein};
	my $nuc = $param->{nucleotide};
	my $genome = $param->{genome};

	# parse and fix information.
	my $search = $param->{search};
	my $taxon = $search->taxon;
	my $organism = $taxon->organism;
	my $strain = $taxon->strain;
	# TODO: !!! FIX THIS !!!
	#my $eexons = $search->family->eexons;
	my $eexons = 3;
		
	my $org_id = $organism;
	my $org_tax = $organism. ".".$taxon->id;

	print STDERR "* org_id: $org_id\n";
	print STDERR "* taxon: $org_tax\n";
	
	print $fh "SEQUENCE", "\t",
		"family", "\t",
		"genome", "\t",
		"strain", "\t",
		"chromosome", "\t",
		"translation", "\t",
		"sequence", "\t",
		"start", "\t",
		"end", "\t",
		"strand", "\t",
		"numexons", "\t",
		"splicing", "\t",
		"pseudogene", "\t",
		"truncated", "\t",
		"rating", "\t",
		"method", "\t",
		"model", "\t",
		"score", "\t",
		"evalue", "\t",
		"hmmloc", "\t",
		"description", "\n";
		
	my %hit_unique;
	my @hit_unique;
	foreach my $hit ($self->hit_list) {
		my $id = $hit->id;
		push @hit_unique, $id if ! exists $hit_unique{$id};
		push @{ $hit_unique{$id} }, $hit;
	}
	
	foreach my $id (@hit_unique) {
		my @hit = @{ $hit_unique{$id} };
		### TODO: fix this !!!!
		#!!!!!!!!!!!!!!!!!!!!!!
		my $hit = $hit[0];
		#!!!!!!!!!!!!!!!!!!!!!!
		
		my $gene = $genome->get_gene_by_id($id);
		
		my $nuc_seq = $nuc->get_seq_by_id($id);
		my $pro_seq = $pro->get_seq_by_id($id);
		if (defined $nuc_seq) {
			$nuc_seq = $nuc_seq->seq;
		} else {
			$nuc_seq = "";
		}
		if (defined $pro_seq) {
			$pro_seq = $pro_seq->seq;
		} else {
			$pro_seq = "";
		}
		
		my @exonloc;
		foreach my $n (1 .. $gene->nexons) {
			my $exon = $gene->get_exon_by_id($n);
			push @exonloc, join "..", $exon->start, $exon->end;
		}
		my $exonloc = join ",", @exonloc;
		
		my $hmmloc = "";
		my @hmmloc;
		foreach my $hit_ (@hit) {
			push @hmmloc, join "..", $hit_->start, $hit_->end if defined $hit_->start and defined $hit_->end;
		}
		$hmmloc = join ",", @hmmloc;
		
		print $fh
			"$id\t",
			$organism.".".$search->family->id, "\t",
			$org_tax, "\t",
			$taxon->strain, "\t",
			$org_tax.".".$gene->chromosome, "\t",
			$pro_seq, "\t",
			$nuc_seq, "\t",
			$gene->start, "\t",
			$gene->end, "\t",
			$gene->strand eq "+" ? "forward" : "reverse", "\t",
			$gene->nexons, "\t",
			$exonloc, "\t",
			$gene->pseudogene ? "TRUE" : "FALSE", "\t",
			"FALSE", "\t",
			$gene->quality($eexons), "\t",
			$hit->method, "\t",
			$search->family->hmm, "\t",
			$hit->score, "\t",
			$hit->significance, "\t",
			$hmmloc, "\t",
			$gene->description, "\n";
	}
}

sub export_fasta {
	my $self = shift;
	my $param = shift;
	
	my $fh = *STDOUT;
	if ($param->{file}) {
		open OUT, ">$param->{file}" or die "[ResultSet::Result::export_fasta] cannot open file $param->{file} for writing: $!\n";
		$fh = *OUT;
	}
	
	my $db = $param->{db};
	foreach my $hit ($self->hit_list) {
		my $seq = $db->get_seq_by_id($hit->id);
		if (defined $seq) {
			print $fh ">", $seq->id, "\n";
			print $fh _format_seq($seq->seq);
		}
	}
}

sub _format_seq {
	my $seq = shift;
	my $seqn = CORE::length $seq;
	$seq =~ s/(.{60})/$1\n/g;
	$seq .= "\n" if $seqn % 60 != 0;
	return $seq;
}

sub export_tab {
	my $self = shift;
	my $param = shift;
	
	my $fh = *STDOUT;
	if ($param->{file}) {
		open OUT, ">$param->{file}" or die "cannot open $param->{file} for writing: $!\n";
		$fh = *OUT;
	}
	
	foreach my $hit ($self->hit_list) {
		print $fh $hit->id, "\t", $hit->score, "\t", $hit->significance, "\n";
	}
}

##########
# functions used by export_pfam
#
# this computes the architeture string.
sub architecture {
	my $self = shift;
	my %tmp;
	
	foreach my $hit ($self->hit_list) {
		#foreach my $hsp ($self->hsp_list) {
			#$tmp{$hsp->start} = $self->id;
			push @{$tmp{$hit->start}}, $hit->id if _check_domain($hit->id);
		#}
	}
	# now order them by the values.
	my @tmp;
	foreach my $key (sort { $a <=> $b } keys %tmp) {
		push @tmp, join "-", @{$tmp{$key}};
	}
	return join ";", @tmp;
}

sub _check_domain {
	my $id = shift;
	
	my @baned_domains = ("Miro", "MMR_HSR1", "GTP_EFTU", "Arf", "ATP_bind_1");
	foreach my $domain (@baned_domains) {
		return 0 if $id eq $domain;
	}
	return 1;
}

sub num_dif_domains {
	my $self = shift;
	my %tmp;
	
	foreach my $hit ($self->hit_list) {
		#foreach my $hsp ($self->hsp_list) {
			#$tmp{$hsp->start} = $self->id;
			my $id = $hit->id;
			$id = "Ras" if !_check_domain($id);
			$tmp{$id}++; # if _check_domain($hit->id);
		#}
	}
	# now order them by the values.
	my @tmp;
	foreach my $key (keys %tmp) {
		push @tmp, "$key#$tmp{$key}";
		#push @tmp, join "-", @{$tmp{$key}};
	}
	return join ";", @tmp;
}


# this computes the nicely formated list of domains,domain location, score and
# evalue.
sub domains_location_str {
	my $self = shift;
	my %domains;
	my @domain_list;
	foreach my $hit ($self->hit_list) {
		#foreach my $hsp ($self->hsp_list) {
			push @domain_list, $hit->id if !exists $domains{$hit->id};
			#push @{ $domains{$hit->name} }, join "..", $hsp->start, $hsp->end;
			#my $chain = $hsp->start."..".$hsp->end."[".$self->score."|".$self->significance."]";
			my $chain = $hit->start."..".$hit->end."[".$hit->score."|".$hit->significance."]";
			push @{ $domains{$hit->id} }, $chain;
		#}
	}
	my @domains;
	foreach my $domain (@domain_list) {
		push @domains, join ":", $domain, join ",", @{ $domains{$domain} };
	}
	return join ";", @domains;
}

1;