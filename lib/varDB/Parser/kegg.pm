package varDB::Parser::kegg;

use varDB::Parser;
use varDB::Location;
@ISA = qw(varDB::Parser);

use strict;
use warnings;

sub new {
	my $class = shift;
	my $self = $class->SUPER::new(@_);
	bless $self, $class;
	return $self;
}

# read the data and store it into the proper fields.
sub process {
	my $self = shift;
	my $param = shift;

	my $in = $self->instance;
	my $dir = $param->{dir};
	my $cnt = unlink "$dir/protein.fa", "$dir/gene.fa", "$dir/gene-trans.fa", "$dir/position.txt";
	#die "error al eliminar old files.\n" if $cnt != 3;
	while (my $seq = $in->next_seq) {
		open OUT, ">>$dir/position.txt" or die "cannot create file $dir/position.txt for writting: $!\n";
		my $id = $seq->accession_number;
		my @pos = $seq->annotation()->get_Annotations('position');
		my $loc = new varDB::Location;
		my $nexons = @pos;
		foreach my $pos (@pos) {;
			my $loc_ = Bio::Factory::FTLocationFactory->from_string($pos->text);
			$loc->add({id => $id, start => $loc_->start, end => $loc_->end});
			my $strand = "+";
			$strand = "-" if $loc_->strand == -1;
			print OUT $seq->accession_number, "\texon\t$nexons\t", $loc_->start, "\t", $loc_->end, "\t$strand\n";
		}
		close OUT;
		
		my @desc = $seq->annotation->get_Annotations('description');
		my $desc = "description:".$desc[0]->display_text.";";
		my $out = new Bio::SeqIO(-file => ">>$dir/protein.fa", -format => 'fasta');
		my $seq_ = new Bio::PrimarySeq(
			-id => $seq->accession_number,
			-accession_number => $seq->accession_number,
			-description => $desc,
			-seq => $seq->translate->seq
		);
		$out->write_seq($seq_);
		
		$out = new Bio::SeqIO(-file => ">>$dir/gene.fa", -format => 'fasta');
		$seq_ = new Bio::PrimarySeq(
			-id => $seq->accession_number,
			-accession_number => $seq->accession_number,
			-description => $desc,
			-seq => $seq->seq
		);
		$out->write_seq($seq_);
		
		my @offset = (1, 2, 3);
		my @revcom = (0, 1);
		$out = new Bio::SeqIO(-file => ">>$dir/gene-trans.fa", -format => 'fasta');
		foreach my $revcom (@revcom) {
			#print STDERR "revcom: $revcom\n";
			foreach my $offset (@offset) {
				#print STDERR "offset: $offset\n";
				#my $seq_ = $seq;
				if ($revcom) {
					$seq_ = $seq_->revcom;
				}
				my $seq__ = $seq_->translate(-offset => $offset);
				
				my $desc = $seq__->description.";revcom:$revcom;offset:$offset";
				$seq__->description($desc);
				
				my $id = $seq__->display_id."-$revcom$offset";
				$seq__->display_id($id);
				
				$out->write_seq($seq__);
			}
		}
	}
}

# save the data with the correct format.
sub dump {
	my $self = shift;
	
	# FIXME.
}

1;
