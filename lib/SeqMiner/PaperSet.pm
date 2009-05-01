package SeqMiner::PaperSet;

use strict;
use warnings;

use SeqMiner::Config;
use SeqMiner::PaperSet::Paper;
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
		my ($id, $ortholog, $keyword) = split '\t', $_;
		my $paper = new SeqMiner::PaperSet::Paper;
		$paper->id($id);
		$paper->ortholog->add($os->get_item_by_id($ortholog));
		$self->add($paper);
	}
	close IN;
}

1;