package SeqMiner::Hmmer;

=head1 MAIN

SeqMiner::SearchSet::Search;

Methods for performing search like operations like search using HMMER or PSI-Blast.

=cut


use strict;
use warnings;

use SeqMiner::Config;
use SeqMiner::ItemSet::Item;
use vars qw( @ISA );
@ISA = ("SeqMiner::ItemSet::Item");

sub new {
	my $class = shift;
	
	my $self = {};
	$self->{infile} = undef;
	$self->{outdir} = undef;
	$self->{outfile} = undef;
	$self->{model} = undef;
	bless $self, $class;
    $self->_initialize(@_);
    return $self;
}

sub _initialize {
	my $self = shift;
}

sub infile {
	my $self = shift;
	$self->{infile} = shift if @_;
	return $self->{infile};
}

sub outfile {
	my $self = shift;
	$self->{outfile} = shift if @_;
	return $self->{outfile};
}

sub outdir {
	my $self = shift;
	$self->{outdir} = shift if @_;
	return $self->{outdir};
}

sub model {
	my $self = shift;
	$self->{model} = shift if @_;
	return $self->{model};
}

sub run {
	my $self = shift;
	$self->debug;
	#my $res = system "hmmpfam", $HMMERPARAM, $model, $file, "> $dir/$outfile";
	#return $res;
	#"hmmpfam $HMMERPARAM $SM_HOME/db/pfam/Pfam_ls_b /tmp/hmmer-tmp.fa > /tmp/hmmer_ls.log";
}

sub debug {
	my $self = shift;
	
	my $model = $self->model;
	my $infile = $self->infile;
	my $outfile = $self->outfile;
	my $outdir = $self->outdir;
	
	print STDERR <<TXT;

Running Hmmpfam...

Parameters: $HMMERPARAM
Model:      $model
Infile:     $infile
Outdir:     $outdir
Outfile:    $outfile

TXT
	
}

1;