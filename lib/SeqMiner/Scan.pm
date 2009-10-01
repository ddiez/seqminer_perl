package SeqMiner::Scan;

use strict;
use warnings;

use SeqMiner::Config;
use SeqMiner::ItemSet::Item;
use base "SeqMiner::ItemSet::Item";

sub new {
	my $class = shift;
	my $self = $class->SUPER::new(@_);
	bless $self, $class;
    $self->_initialize(@_);
    return $self;
}

sub _initialize {
	my $self = shift;
}

sub search {
	my $self = shift;
	my $param = shift;
	
	return -1 if ! defined $param->{source};
	return -1 if ! defined $param->{type};
	
	my $res = undef;
	if ($param->{source} eq "genome") {
		return 2 if ($self->source eq "isolate");
		if ($param->{type} eq "pfam") {
			$res = $self->_search_pfam_genome;
		}
	} elsif($param->{source} eq "isolate") {
		return 2 if ($param->{type} eq "genome");
		foreach my $db (values %TARGET_DB) {
			if ($param->{type} eq "pfam") {
				$res = $self->_search_pfam_isolate($db);
			}
		}
	}
	
	return $res;
}

sub _search_pfam_genome {
	my $self = shift;
	
	use SeqMiner::Hmmer::Hmmpfam;
	my $hmmer = new SeqMiner::Hmmer::Hmmpfam;
	
	$self->chdir('fasta');
	
	# first we do protein sequences:
	my $base = $self->ortholog->name."-".$self->taxon->organism."-protein";
	
	$hmmer->infile($base.".fa");
	$hmmer->outdir($self->dir('pfam'));
	
	$hmmer->outfile($base."_ls.log");
	$hmmer->model("$SM_HOME/db/pfam/Pfam_ls.bin");
	$hmmer->run;
	
	$hmmer->outfile($base."_fs.log");
	$hmmer->model("$SM_HOME/db/pfam/Pfam_fs.bin");
	$hmmer->run;
}

sub _search_pfam_isolate {
	my $self = shift;
	
	#print STDERR "## NOT YET IMPLEMENTED\n";
}


1;