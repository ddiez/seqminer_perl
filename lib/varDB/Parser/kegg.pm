package varDB::Parser::kegg;

use varDB::Parser;
use varDB::Location;
@ISA = qw(varDB::Parser);

use strict;
use warnings;

sub new {
	my $class = shift;
	
	# check file type passed.
	
	# if it is a sequence file, call SUPER to load it.
	my $self = $class->SUPER::new(@_);
	
	# if not, load it properly.
	
	# add class specific slots.
	
	bless $self, $class;
	
	return $self;
}

# read the data and store it into the proper fields.
sub process {
	my $self = shift;
	my $param = shift;
	# store sequences (nuc and protein).
	# store localization.
	my $in = $self->instance;
	my $output = $param->{output};
	my $out = new Bio::SeqIO(-fh => \*STDOUT, -format => 'fasta') if $output eq "protein" or $output eq "gene" or $output eq "nucleotide";
	#print STDERR "type: ", $self->type, "\n";
	while (my $seq = $in->next_seq) {
		if ($output eq "position") {
			my $id = $seq->accession_number;
			my @pos = $seq->annotation()->get_Annotations('position');
			my $loc = new varDB::Location;
			my $nexons = @pos;
			foreach my $pos (@pos) {;
				my $loc_ = Bio::Factory::FTLocationFactory->from_string($pos->text);
				$loc->add({id => $id, start => $loc_->start, end => $loc_->end});
				my $strand = "+";
				$strand = "-" if $loc_->strand == -1;
				print $seq->accession_number, "\texon\t$nexons\t", $loc_->start, "\t", $loc_->end, "\t$strand\n";
			}
		} elsif ($output eq "protein") {
			my $seq_ = new Bio::PrimarySeq(
				-seq => $seq->translate->seq,
				-id => $seq->accession_number,
				-accession_number => $seq->accession_number);
				
			$out->write_seq($seq_);
		} elsif ($output eq "nucleotide" or $output eq "gene") {
			my $seq_ = new Bio::PrimarySeq(
				-seq => $seq->seq,
				-id => $seq->accession_number,
				-accession_number => $seq->accession_number);
				
			$out->write_seq($seq_);
		} else {
			die "[varDB::Parser::kegg::process] unknown output type $output.\n";
		}
	}
	
	# print STDERR "type: ", $self->type, "\n";
	# if ($self->type eq "gene" or $self->type eq "protein") {
		# while (my $seq = $in->next_seq) {
			# my ($org, $id) = split ':', $seq->display_id;
			# # FIXME: get long name for organisms, maybe from KEGG tables.
			# my $desc = $seq->description;
			# $desc = "organism:$org;description:$desc";
			# print STDERR ">$id $desc\n";
		# }
	# } elsif ($self->type eq "genome") {
		# #
	# } elsif ($self->type eq "position") {
		# #
		# my $foo = _parse_position_file($self->file);
		# #print $foo, "\n";
		# #print $foo->{nseq}, "\n";
		# #print $foo->{id}->[0], "\n";
# 
		# foreach my $pos (0 .. $foo->{nseq}-1) {
			# foreach my $exon (1 .. $foo->{exons}->[$pos]) {
				# print 	$foo->{id}->[$pos], "\t",
						# "exon\t", $exon, "\t",
						# $foo->{start}->[$pos], "\t",
						# $foo->{end}->[$pos], "\t",
						# $foo->{strand}->[$pos], "\n";
			# }
		# }
	# } else {
		# die "[varDB::Parse::kegg] unknown type ", $self->type, "\n";
	# }
}

# save the data with the correct format.
sub dump {
	my $self = shift;
	
	# FIXME.
}

sub _parse_position_file {
	my $file = shift;
	open IN, $file or die "ERROR [parse_list_file]: cannot open file $file: $!\n";
	my %location;
	my @id;
	my @position;
	my @exons;
	my @strand;
	my @length;
	my @start;
	my @end;
	my $n = 0;
	while (<IN>) {
		chomp;
		my @line = split '\t', $_;
		push @id, $line[0];
		push @position, $line[3];
		my ($strand, $length, $exons, $start, $end) = _parse_position($line[3]);
		push @exons, $exons;
		push @strand, $strand;
		push @length, $length;
		push @start, $start;
		push @end, $end;
		$n++;
	}
	close IN;
	$location{id} = \@id;
	$location{position} = \@position;
	$location{exons} = \@exons;
	$location{strand} = \@strand;
	$location{start} = \@start;
	$location{end} = \@end;
	$location{nseq} = $n;
	return \%location;
}

# FIXME: exon detection.
sub _parse_position {
	my $position = shift;
	my $length;
	my $strand = "+";
	my $exons = 1;
	
	# first check strand.
	if ($position =~ /complement\((.+)\)/) {
		$strand = "-";
		$position = $1;
	}
	my ($start, $end) = split '\.\.', $position;
	
	return ($strand, $length, $exons, $start, $end);
}

1;