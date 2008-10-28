package varDB::NCBI::PaperSet;

use strict;
use warnings;
use varDB::Config;
use varDB::NCBI::Paper;
use varDB::Ortholog;
use varDB::OrthologSet;
use varDB::ItemSet;
use vars qw( @ISA );
@ISA = ("varDB::ItemSet");

sub new {
	my $class = shift;
	
	my $self = {};
	
	bless $self, $class;
    $self->_initialize(@_);
    return $self;
}

sub _initialize {
	my $self = shift;
	
	my $os = new varDB::OrthologSet;
	
	open IN, "$VARDB_PAPER_FILE" or die "$!";
	while (<IN>) {
		next if /^[#|\n|pubmed_id]/;
		chomp;
		my ($id, $ortholog_id, $database_id) = split '\t', $_;
		my $paper = $self->get_item_by_id($id);
		if (! defined $paper) {
			$paper = new varDB::NCBI::Paper($_);
			$paper->id($id);
			$paper->ortholog(new varDB::ItemSet);
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