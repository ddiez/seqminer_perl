package varDB::ListIO;

use varDB::Position;
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
	
	my $file = $param->{file};
	open TMP, $file or die "ERROR [parse_list_file]: cannot open file $file: $!\n";
	
	$self->{file} = $file;
	while (<TMP>) {
		chomp;
		my ($id, $score, $evalue) = split '\t', $_;
		if (! exists $self->{gene}->{$id}) {
			$self->{gene}->{$id}->{score} = $score;
			$self->{gene}->{$id}->{evalue} = $evalue;
			$self->{gene}->{$id}->{quality} = "";
			$self->{gene}->{$id}->{eexons} = 0;
			$self->{gene}->{$id}->{pexons} = 0;
			push @{$self->{gene_list}}, $id;
			$self->{nseq}++;
		} else {
			print STDERR "WARNING [ListIO:_initialize]: duplicated id $id\n";
		}
	}
	close TMP;
}

sub get_file {
	return shift->{file};
}

sub get_gene_list {
	my $self = shift;
	my $fix = shift;
	if ($fix) {
		return fix_array_id($self->{gene_list});
	} else {
		return $self->{gene_list};
	}
}

sub has_id {
	my $self = shift;
	my $id = shift;
	return 1 if exists $self->{gene}->{$id};
}

sub get_number {
	return shift->{nseq};
}

sub get_id {
	return shift->{gene_list}->[shift];
}

sub get_score {
	my $self = shift;
	my $id = shift;
	return $self->{gene}->{$id}->{score};
}

sub get_evalue {
	my $self = shift;
	my $id = shift;
	return $self->{gene}->{$id}->{evalue};
}

sub get_quality {
	my $self = shift;
	my $id = shift;
	return $self->{gene}->{$id}->{quality};
}

sub set_quality {
	my $self = shift;
	my $id = shift;
	$self->{gene}->{$id}->{quality} = shift;
}

=head3 get_eexons set_eexons
	Get and sets expected exons.
=cut
sub get_eexons {
	my $self = shift;
	my $id = shift;
	return $self->{gene}->{$id}->{eexons};
}

sub set_eexons {
	my $self = shift;
	my $id = shift;
	$self->{gene}->{$id}->{eexons} = shift;
}

=head3 get_pexons set_pexons
	Get and sets predicted exons.
=cut
sub get_pexons {
	my $self = shift;
	my $id = shift;
	return $self->{gene}->{$id}->{pexons};
}

sub set_pexons {
	my $self = shift;
	my $id = shift;
	$self->{gene}->{$id}->{pexons} = shift;
}

sub check_exons {
	my $self = shift;
	my $eexons = shift;
	my $pos = shift;
	my $gene_trans = shift;
	
	foreach my $id (@{$self->get_gene_list}) {
		# fix gene_trans ids.
		my $fixid = $id;
		$fixid = fix_id($id) if $gene_trans == 1;
		#print STDERR ">$id#$fixid#\t";
		my $nexons = $pos->get_nexons($fixid);
		#my $strain = $pos->get_strain;
		$self->set_eexons($id, $eexons);
		$self->set_pexons($id, $nexons);
		#print STDERR ">$nexons#\n";
		if ($nexons != $eexons) {
			if ($nexons == 1) {
				# could be a processed pseudogene.
				$self->set_quality($id, $QUALITY_SCORE{1});
			} else {
				$self->set_quality($id, $QUALITY_SCORE{0});
			}
		} else { # good number of exons.
			$self->set_quality($id, $QUALITY_SCORE{2});
		}
	}
}

sub print {
	my $self = shift;
	my $param = shift;
	
	my $file = $self->get_file;
	$file = $param->{file} if defined $param->{file};
	open OUTLIST, ">$file";
	foreach my $id (@{$self->get_gene_list}) {
		my $score = $self->get_score($id);
		my $evalue = $self->get_evalue($id);
		my $quality = $self->get_quality($id);
		my $eexons = $self->get_eexons($id);
		my $pexons = $self->get_pexons($id);
		print OUTLIST "$id\t$score\t$evalue\t$eexons\t$pexons\t$quality\n";
	}
	
	close OUTLIST;
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
	
	my $file = $self->get_file;
	$file = $param->{file} if defined $param->{file};
	open OUT, ">$file" or die "[ListIO::export_nelson] cannot open file $file for writing: $!\n";
	print OUT "SEQUENCE\tfamily\tgenome\tstrain\tchromosome\ttranslation\tsequence\tstrand\texons\tpseudogene\ttruncated\trating\n"; 
	foreach my $id (@{$self->get_gene_list}) {
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
			$self->get_quality($id), "\n";
	}
	close OUT;
}

=head3 fix_array_id
	Fixes every element of an array removing the ORF number at the end of the
	identifiers. Returns a reference to a new array containing the fixed
	identifiers.
=cut
sub fix_array_id {
	my $id_orig = shift;
	my @id_fixed = ();
	foreach my $id (@{$id_orig}) {
		push @id_fixed, fix_id($id);
	}
	return \@id_fixed;
}

sub fix_id {
	my $id = shift;
	$id =~  s/(.+)-.+/$1/;
	return $id;
}

1;
