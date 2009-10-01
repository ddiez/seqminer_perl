package SeqMiner::Config;
require Exporter;

=head1 MAIN

This module contains exported global variables for SeqMiner (a.k.a. as SeqMiner Framework)

=cut

use strict;
use warnings;

our @ISA = qw/Exporter/;
our @EXPORT = qw/$SM_RELEASE $SM_HOME $SM_SEARCH_FILE
	$SM_ORGANISM_FILE $SM_TAXON_FILE $SM_FILTER_FILE $SM_PAPER_FILE
	$SM_AUTHOR_FILE $SM_KEYWORD_FILE $SM_SEARCH_DIR $UNIPROTDB $PDBDB
	$HMMDB $GENOMEDB $PFAM_VERSION $DEBUG $SM_COMMIT_DIR $HMMERPARAM
	$WISEPARAM $PSIBLASTDB $PSSM_ITER $PSSM_EVALUE $SM_ORTHOLOG_FILE
	$SM_MINING_DIR %TARGET_DB $SM_FAMILY_FILE $SM_PROJECT/;

our $SM_RELEASE = 1;
our $DEBUG = 1;

our $SM_HOME = "/Volumes/Biodev/projects/vardb";
our $SM_PROJECT = "vardb";

our $SM_SEARCH_FILE = "$SM_HOME/etc/search.txt";
our $SM_ORGANISM_FILE = "$SM_HOME/etc/organisms.txt";
our $SM_FILTER_FILE = "$SM_HOME/etc/filter.txt";
our $SM_PAPER_FILE = "$SM_HOME/etc/paper.txt";
our $SM_AUTHOR_FILE = "$SM_HOME/etc/author.txt";
our $SM_KEYWORD_FILE = "$SM_HOME/etc/keyword.txt";

our $SM_TAXON_FILE = "$SM_HOME/etc/taxon.txt";
our $SM_ORTHOLOG_FILE = "$SM_HOME/etc/ortholog.txt";
our $SM_FAMILY_FILE = "$SM_HOME/etc/family.txt";

our $SM_COMMIT_DIR = "$SM_HOME/web/trunk/data/diego/";
our $SM_MINING_DIR = "$SM_HOME/mining";
our $SM_SEARCH_DIR = "$SM_MINING_DIR/vardb-$SM_RELEASE";
$SM_SEARCH_DIR = "$SM_MINING_DIR/last" if $DEBUG == 1;


our $UNIPROTDB = "$SM_HOME/db/uniprot";
our $PDBDB = "$SM_HOME/db/pdb";
our $HMMDB = "$SM_HOME/db/pfam";
our $PFAM_VERSION = "pfam-22";
our $GENOMEDB = "$SM_HOME/db/genomes";
our $PSIBLASTDB = "$SM_HOME/db/psiblast";

our $HMMER_EVALUE = 1e-2;
our $PSSM_EVALUE = 1e-3;
our $PSSM_ITER = 3;

our %TARGET_DB = (
	nuccore => "core",
	nucest  => "est"
);

my $OPTIMIZE = 1;
if ($OPTIMIZE) {
	our $HMMERPARAM = "--cpu 8";
	our $WISEPARAM = "-quiet -aln 500 -pthread -pthr_no 8";
	our $BLASTPARAM = "";
} else {
	our $HMMERPARAM = "--cpu 1";
	our $WISEPARAM = "-quiet -aln 500 -serial";
	our $BLASTPARAM = "";
}

1;