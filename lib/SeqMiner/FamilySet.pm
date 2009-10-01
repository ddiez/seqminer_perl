package SeqMiner::FamilySet;

use strict;
use warnings;
use SeqMiner::Config;
use SeqMiner::Family;
use SeqMiner::ItemSet;
use base "SeqMiner::ItemSet";

sub new {
	my $class = shift;
	my $self = $class->SUPER::new(@_);
	bless $self, $class;
    $self->_initialize(@_);
    return $self;
}

sub _initialize {
	my $self = shift;
	my $param = shift;

	if (defined $param->{empty}) {
		return if $param->{empty} == 1;
	}
	
	open IN, "$SM_FAMILY_FILE" or die "$!";
	while (<IN>) {
		next if /^[#|\n]/;
		chomp;
		my ($taxon, $ortholog, $name) = split '\t', $_;
		my $id = "$taxon.$ortholog";
		my $family = new SeqMiner::Family();
		$family->id($id);
		$family->name($name);
		$family->taxon($taxon);
		$family->ortholog($ortholog);
		$self->add($family);
	}
	close IN;
}

sub debug {
	my $self = shift;
	print STDERR "#---", ref $self, "--->\n";
	print STDERR "* number of families: ", $self->length, "\n";
	for my $f ($self->item_list) {
		print STDERR "* ", $f->id, "\t", $f->ortholog, "\t", $f->name, "\n";
	}
	print STDERR "\\\\\n";
}

1;