package SeqMiner::Ortholog;

use strict;
use warnings;
use SeqMiner::Config;
use SeqMiner::ItemSet::Item;
use vars qw( @ISA );
@ISA = ("SeqMiner::ItemSet::Item");

sub new {
	my $class = shift;
	
	my $self = {};
	bless $self, $class;
    $self->_initialize(@_);
    return $self;
}

sub _initialize {
	my $self = shift;
}

# an alias to id.
sub name {
	shift->id(@_);
}

sub hmm {
	my $self = shift;
	$self->{hmm} = shift if @_;
	return $self->{hmm};
}

# TODO: add support for alternative libraries (ves1) and missing models (esag6_7)
sub update_hmm {
	my $self = shift;
	
	print STDERR "## UPDATE HMM MODELS\n";
	$self->debug;
	my $hmm_name = $self->hmm;
	
	print STDERR "* fetching Pfam models ... ";
	system "hmmfetch $SM_HOME/db/pfam/Pfam_ls.bin $hmm_name > $SM_HOME/db/models/hmm/ls/$hmm_name";
	system "hmmfetch $SM_HOME/db/pfam/Pfam_fs.bin $hmm_name > $SM_HOME/db/models/hmm/fs/$hmm_name";
	print STDERR "OK\n";
}

sub update_seed {
	my $self = shift;
}

sub debug {
	my $self = shift;
	print STDERR "* taxon: ", $self->name, "\n";
	print STDERR "* hmm: ", $self->hmm, "\n\n";
}


1;
