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
use varDB::Organism;

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

sub merge {
	my $self = shift;
	my $res = shift;
	foreach my $hit ($res->hit_list) {
		if (!$self->has_hit($hit)) {
			$self->add_hit($hit);
		}
	}
}

sub export_nelson {
	my $self = shift;
	my $param = shift;
	
	my $org = new varDB::Organism;
	
	my $pro = $param->{protein};
	my $nuc = $param->{nucleotide};
	$pro->set_uc;
	$nuc->set_uc;
	#
	my $genome = $param->{genome};

	# parse and fix information.
	my $info = $param->{info};
	my $organism = $info->organism;
	my $strain = $info->strain;
	my $eexons = $info->eexons;
		
	my $org_id = $organism;
	$org_id = $organism."_".$strain if $strain ne "-";
	my $taxon = $org->taxonid($org_id);
	my $org_tax = $organism. ".".$taxon if $taxon ne "";

	print STDERR "* org_id: ", $org_id, "\n";
	print STDERR "* taxon: ", $org->taxonid($org_id), "\n";

	open OUT, ">$param->{file}" or die "[SearchResult::export_nelson] cannot open file $param->{file} for writing: $!\n";
	print OUT "SEQUENCE", "\t",
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
	foreach my $hit ($self->hit_list) {
		my $id = $hit->id;
		my $gene = $genome->get_gene_by_id($id);
		
		my $nuc_seq = $nuc->get_seq($id);
		my $pro_seq = $pro->get_seq($id);
		$nuc_seq = "" if !defined $nuc_seq;
		$pro_seq = "" if !defined $pro_seq;
		
		my @exonloc;
		foreach my $n (1 .. $gene->nexons) {
			my $exon = $gene->get_exon_by_id($n);
			push @exonloc, join "..", $exon->start, $exon->end;
		}
		my $exonloc = join ",", @exonloc;
		
		#my @hmmloc;
		#foreach my $hsp ($hit->hsp_list) {
		#	push @hmmloc, join "..", $hsp->start, $hsp->end;
		#}
		#my $hmmloc = join ",", @hmmloc;
		my $hmmloc = "";
		$hmmloc = join ",", join "..", $hit->start, $hit->end if defined $hit->start and defined $hit->end;
		
		print OUT
			"$id\t",
			$organism.".".$info->family, "\t",
			#$organism."."."foo_fam", "\t",
			$org_tax, "\t",
			$org->strain($org_id), "\t",
			$org_tax.".".$gene->chromosome, "\t",
			$pro_seq, "\t",
			$nuc_seq, "\t",
			$gene->start, "\t",
			$gene->end, "\t",
			$gene->strand eq "+" ? "forward" : "reverse", "\t",
			$gene->nexons, "\t",
			$exonloc, "\t",
			"\t",
			"\t",
			$gene->quality($eexons), "\t",
			$hit->method, "\t",
			$hit->model, "\t",
			$hit->score, "\t",
			$hit->significance, "\t",
			$hmmloc, "\t",
			$gene->description, "\n";
	}
	close OUT;
}

sub export_fasta {
	my $self = shift;
	my $param = shift;
	
	my $db = $param->{db};
	open OUT, ">$param->{file}" or die "[SearchResult::export_nelson] cannot open file $param->{file} for writing: $!\n";
	foreach my $hit ($self->hit_list) {
		my $seq = $db->get_seq($hit->id);
		if (defined $seq) {
			$seq =~ s/(.{60})/$1\n/g;
			print OUT ">".$hit->id."\n";
			print OUT "$seq\n";
		}
	}
	close OUT;
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
			$tmp{$hit->start} = $hit->id;
		#}
	}
	# now order them by the values.
	my @tmp;
	foreach my $key (sort { $a <=> $b } keys %tmp) {
		push @tmp, $tmp{$key};
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