package SeqMiner::NCBI::PaperSet;

use strict;
use warnings;
use SeqMiner::Config;
use SeqMiner::NCBI::Paper;
use SeqMiner::Ortholog;
use SeqMiner::OrthologSet;
use SeqMiner::ItemSet;
use vars qw( @ISA );
@ISA = ("SeqMiner::ItemSet");

sub new {
	my $class = shift;
	
	my $self = {};
	
	bless $self, $class;
    $self->_initialize(@_);
    return $self;
}

sub _initialize {
	my $self = shift;
	
	my $os = new SeqMiner::OrthologSet;
	
	open IN, "$SM_PAPER_FILE" or die "$!";
	while (<IN>) {
		next if /^[#|\n|pubmed_id]/;
		chomp;
		my ($id, $ortholog_id, $database_id) = split '\t', $_;
		my $paper = $self->get_item_by_id($id);
		if (! defined $paper) {
			$paper = new SeqMiner::NCBI::Paper($_);
			$paper->id($id);
			$paper->ortholog(new SeqMiner::ItemSet);
			$self->add($paper);
		}
		$paper->database($database_id);
		my $ortholog = $os->get_item_by_id($ortholog_id);
		if (defined $ortholog) {
			$paper->ortholog->add($ortholog);
		} else {
			die "ERROR [PaperSet] ortholog ($ortholog) not found!";
		}
	}
	close IN;
}

# scan all papers in a Paper object.
sub scan {
	my $self = shift;
	foreach my $paper ($self->item_list) {
		my @id = $paper->scan;
		#$paper->get_seqs(\@id);
		$paper->filter;
	}
}

1;