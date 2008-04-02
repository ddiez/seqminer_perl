package varDB::SearchResult;

#use varDB::Position;
use strict;
use warnings;

our %QUALITY_SCORE = (
	0 => 'ONE_STAR',
	1 => 'TWO_STARS',
	2 => 'THREE_STARS',
);

sub new {
	my $class = shift;
	
	my $self = {};
	bless $self, $class;
    $self->_initialize(@_);
    return $self;
}

sub _initialize {
	my $self = shift;
	my $param = shift;
	
	$self->{file} = $param->{file};
	$self->{search_type} = $param->{search_type};
	if ($param->{search_type} eq "hmmer") {
		$self->_parse_hmmer_file($param->{file});
	} elsif ($param->{search_type} eq "genewise") {
		$self-> _parse_genewise_file($param->{file});
	} else {
		die "[SearchResult:_initialize] unknown search_type: $param->{search_type}\n";
	}
}

sub add {
	my $self = shift;
	my $id = shift;
	$self->{id}->{$id}->{score} = "";
	$self->{id}->{$id}->{evalue} = "";
	$self->{id}->{$id}->{quality} = "";
	$self->{id}->{$id}->{eexons} = 0;
	$self->{id}->{$id}->{pexons} = 0;
	$self->{id}->{$id}->{strand} = "";
	$self->{id}->{$id}->{method} = "";
	push @{$self->{id_list}}, $id;
	$self->{nids}++; 
}

sub merge {
	my $self = shift;
	my $list = shift;
	foreach my $id (@{ $list->id_list }) {
		if ($self->has_id($id)) {
			if ($list->evalue($id) < $self->evalue($id)) {
				$self->score($id, $list->score($id));
				$self->evalue($id, $list->evalue($id));
				$self->quality($id, $list->quality($id));
				$self->eexons($id, $list->eexons($id));
				$self->pexons($id, $list->pexons($id));
				$self->strand($id, $list->strand($id));
				$self->method($id, $list->method($id));
			}
		} else {
			$self->add($id);
			$self->score($id, $list->score($id));
			$self->evalue($id, $list->evalue($id));
			$self->quality($id, $list->quality($id));
			$self->eexons($id, $list->eexons($id));
			$self->pexons($id, $list->pexons($id));
			$self->strand($id, $list->strand($id));
			$self->method($id, $list->method($id));
		}
	}
}

sub length {
	return shift->{nids};
}

sub file {
	return shift->{file};
}

sub id_list {
	return shift->{id_list};
}

sub has_id {
	my $self = shift;
	my $id = shift;
	exists $self->{id}->{$id} ? return 1 : return 0;
}

sub score {
	my $self = shift;
	my $id = shift;
	$self->{id}->{$id}->{score} = shift if @_;
	return $self->{id}->{$id}->{score};
}

sub evalue {
	my $self = shift;
	my $id = shift;
	$self->{id}->{$id}->{evalue} = shift if @_;
	return $self->{id}->{$id}->{evalue};
}

sub quality {
	my $self = shift;
	my $id = shift;
	$self->{id}->{$id}->{quality} = shift if @_;
	return $self->{id}->{$id}->{quality};
}

sub strand {
	my $self = shift;
	my $id = shift;
	$self->{id}->{$id}->{strand} = shift if @_;
	return $self->{id}->{$id}->{strand};
}

sub method {
	my $self = shift;
	my $id = shift;
	$self->{id}->{$id}->{method} = shift if @_;
	return $self->{id}->{$id}->{method};
}

sub model {
	my $self = shift;
	my $id = shift;
	$self->{id}->{$id}->{model} = shift if @_;
	return $self->{id}->{$id}->{model};
}

sub eexons {
	my $self = shift;
	my $id = shift;
	$self->{id}->{$id}->{eexons} = shift if @_;
	return $self->{id}->{$id}->{eexons};
}

sub pexons {
	my $self = shift;
	my $id = shift;
	$self->{id}->{$id}->{pexons} = shift if @_;
	return $self->{id}->{$id}->{pexons};
}

sub check_exons {
	my $self = shift;
	my $eexons = shift;
	my $pos = shift;
	#my $gene_trans = shift;
	
	foreach my $id (@{$self->id_list}) {
		# fix gene_trans ids.
		#my $fixid = $id;
		#$fixid = _fix_id($id) if $gene_trans == 1;
		#print STDERR ">$id#$fixid#\t";
		my $nexons = $pos->get_nexons($id);
		#my $strain = $pos->get_strain;
		$self->eexons($id, $eexons);
		$self->pexons($id, $nexons);
		#print STDERR ">$nexons#\n";
		if ($nexons != $eexons) {
			if ($nexons == 1) {
				# could be a processed pseudogene.
				$self->quality($id, $QUALITY_SCORE{1});
			} else {
				$self->quality($id, $QUALITY_SCORE{0});
			}
		} else { # good number of exons.
			$self->quality($id, $QUALITY_SCORE{2});
		}
	}
}

sub print {
	my $self = shift;
	my $param = shift;
	
	open OUT, ">$param->{file}" or die "[SearchResult::print] cannot open file $param->{file} for writing: $!\n";
	foreach my $id (@{$self->id_list}) {
		my $score = $self->score($id);
		my $evalue = $self->evalue($id);
		my $eexons = $self->eexons($id);
		my $pexons = $self->pexons($id);
		my $quality = $self->quality($id);
		my $method = $self->method($id);
		print OUT "$id\t$score\t$evalue\t$eexons\t$pexons\t$quality\t$method\n";
	}
	close OUT;
}

sub export_nelson {
	my $self = shift;
	my $param = shift;
	
	# que sequence objects.
	my $pro = $param->{protein};
	my $nuc = $param->{nucleotide};
	$pro->set_uc;
	$nuc->set_uc;
	#
	my $genome = $param->{genome};
	
	# parse and fix information.
	my $info = $param->{info};
	my $organism = $info->{organism};
	my $strain = $info->{strain};
	my $family = "$organism.".$info->{family};
	
	open OUT, ">$param->{file}" or die "[SearchResult::export_nelson] cannot open file $param->{file} for writing: $!\n";
	print OUT "SEQUENCE\tfamily\tgenome\tstrain\tchromosome\ttranslation\t",
		"sequence\tstrand\texons\tpseudogene\ttruncated\trating\n"; 
	foreach my $id (@{ $self->id_list }) {
		# chromosome?
		my $gene = $genome->get_gene($id);
		my $chromosome = "$organism.".$gene->get_chromosome;
		my $strand = "forward";
		$strand = "reverse" if $gene->get_strand eq "-";
		my $nexons = $gene->get_nexons;
		my $nuc_seq = $nuc->get_seq($id);
		my $pro_seq = $pro->get_seq($id);
		$nuc_seq = "" if !defined $nuc_seq;
		$pro_seq = "" if !defined $pro_seq;
		print OUT "$id\t",
			$family, "\t",
			$organism, "\t",
			uc $strain, "\t",
			"$chromosome\t",
			$pro_seq, "\t",
			$nuc_seq, "\t",
			"$strand\t",
			"$nexons\t",
			"\t",
			"\t",
			$self->quality($id), "\n";
	}
	close OUT;
}

sub _parse_hmmer_file {
	my $self = shift;
	my $file = shift;
	my $cutoff = shift;
	
	$cutoff = 0.01 if !defined $cutoff; # set default cutoff.
	open IN, $file or die "[SearchResult:_parse_hmmer_file]: cannot open file $file: $!\n";
	while (<IN>) {
		next unless /^Scores for complete sequences/;
		while (<IN>) {
			last if /^[\n]$/;
			next if /^Sequence\s+Description/o || /^\-\-\-/o;
			chomp;
			my @line = split;
			my ($id, $n, $evalue, $score) = (shift @line, pop @line, pop @line, pop @line);
			if ($evalue <= $cutoff) {
				$self->{id}->{$id}->{score} = $score;
				$self->{id}->{$id}->{evalue} = $evalue;
				$self->{id}->{$id}->{quality} = "";
				$self->{id}->{$id}->{eexons} = 0;
				$self->{id}->{$id}->{pexons} = 0;
				$self->{id}->{$id}->{strand} = "";
				$self->{id}->{$id}->{method} = "hmmer";
				push @{$self->{id_list}}, $id;
				$self->{nids}++;
			}
		}
	}
	close IN;
}

sub _parse_genewise_file {
	my $self = shift;
	my $file = shift;
	my $cutoff = shift;
	
	$cutoff = 0.01 if !defined $cutoff; # set default cutoff.
	
	open IN, $file or die "[SearchResult:_parse_genewise_file]: cannot open file $file: $!\n";
	while (<IN>) {
		next unless /^#High Score list/;
		my $skip = <IN>;
		$skip = <IN>;
		while (<IN>) {
			last if /^[\n]$/;
			chomp;
			my ($search1, $hmm, $search2, $strand, $id, $score, $evalue) = split /\s+/, $_;
			if ($evalue <= $cutoff) {
				$self->{id}->{$id}->{score} = $score;
				$self->{id}->{$id}->{evalue} = $evalue;
				$self->{id}->{$id}->{quality} = "";
				$self->{id}->{$id}->{eexons} = 0;
				$self->{id}->{$id}->{pexons} = 0;
				$self->{id}->{$id}->{strand} = $strand =~ /\[(.)\]/ ? $1 : "";
				$self->{id}->{$id}->{method} = "genewise";
				push @{$self->{id_list}}, $id;
				$self->{nids}++;
			}
		}
	}
	close IN;
}

sub _fix_array_id {
	my $id_orig = shift;
	my @id_fixed = ();
	foreach my $id (@{$id_orig}) {
		push @id_fixed, fix_id($id);
	}
	return \@id_fixed;
}

sub _fix_id {
	my $id = shift;
	$id =~  s/(.+)-.+/$1/;
	return $id;
}

1;
