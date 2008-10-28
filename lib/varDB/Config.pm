package varDB::Config;

use strict;
use warnings;

our @ISA = qw/Exporter/;
our @EXPORT = qw/$VARDB_RELEASE $VARDB_HOME $VARDB_SEARCH_FILE
	$VARDB_ORGANISM_FILE $VARDB_TAXON_FILE $VARDB_FILTER_FILE $VARDB_PAPER_FILE
	$VARDB_AUTHOR_FILE $VARDB_KEYWORD_FILE $VARDB_SEARCH_DIR $UNIPROTDB $PDBDB
	$HMMDB $GENOMEDB $PFAM_VERSION $DEBUG $VARDB_COMMIT_DIR $HMMERPARAM
	$WISEPARAM $PSIBLASTDB $PSSM_ITER $PSSM_EVALUE $VARDB_ORTHOLOG_FILE
	$VARDB_MINING_DIR/;

our $VARDB_RELEASE = 1;
our $DEBUG = 1;

our $VARDB_HOME = "/Volumes/Data/projects/vardb";

our $VARDB_SEARCH_FILE = "$VARDB_HOME/etc/search.txt";
our $VARDB_ORGANISM_FILE = "$VARDB_HOME/etc/organisms.txt";
our $VARDB_TAXON_FILE = "$VARDB_HOME/etc/taxon.txt";
our $VARDB_FILTER_FILE = "$VARDB_HOME/etc/filter.txt";
our $VARDB_PAPER_FILE = "$VARDB_HOME/etc/paper.txt";
our $VARDB_AUTHOR_FILE = "$VARDB_HOME/etc/author.txt";
our $VARDB_KEYWORD_FILE = "$VARDB_HOME/etc/keyword.txt";
our $VARDB_ORTHOLOG_FILE = "$VARDB_HOME/etc/ortholog.txt";

our $VARDB_COMMIT_DIR = "$VARDB_HOME/web/data/diego/";
our $VARDB_MINING_DIR = "$VARDB_HOME/mining";
our $VARDB_SEARCH_DIR = "$VARDB_MINING_DIR/vardb-$VARDB_RELEASE";
$VARDB_SEARCH_DIR = "$VARDB_MINING_DIR/last" if $DEBUG == 1;


our $UNIPROTDB = "$VARDB_HOME/db/uniprot";
our $PDBDB = "$VARDB_HOME/db/pdb";
our $HMMDB = "$VARDB_HOME/db/pfam";
our $PFAM_VERSION = "pfam-22";
our $GENOMEDB = "$VARDB_HOME/db/genomes";
our $PSIBLASTDB = "$VARDB_HOME/db/psiblast";

my $HMMER_EVALUE = 1e-2;
my $PSSM_EVALUE = 1e-3;
my $PSSM_ITER = 3;

my $OPTIMIZE = 1;
if ($OPTIMIZE) {
	our $HMMERPARAM = "--cpu 2";
	our $WISEPARAM = "-quiet -aln 500 -pthread -pthr_no 2";
	our $BLASTPARAM = "";
} else {
	our $HMMERPARAM = "--cpu 1";
	our $WISEPARAM = "-quiet -aln 500 -serial";
	our $BLASTPARAM = "";
}

1;