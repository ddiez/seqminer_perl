package SeqMiner::NCBI::Filter;

use strict;
use warnings;
use SeqMiner::Config;

sub new {
	my $class = shift;
	
	my $self = {};
	
	bless $self, $class;
    $self->_initialize(@_);
    return $self;
}

sub _initialize {
	my $self = shift;
	
	open IN, "$SM_FILTER_FILE" or die "$!";
	while (<IN>) {
		next if /^#/;
		chomp;
		my ($source, $pubmed, $title, $keywords) = split '\t', $_;
		
		push @{ $self->{'SOURCE'}}, $source if defined $source;
		push @{ $self->{'PUBMED'}}, $pubmed if defined $pubmed;
		push @{ $self->{'TITLE'}}, $title if defined $title;
		#push @{ $self->{'KEYWORDS'}}, $keywords if defined $keywords;
	}
	close IN;
}


sub get {
	my $self = shift;
	my $what = shift;
	
	return $self->{$what} if exists $self->{$what};
	return undef;
}

1;