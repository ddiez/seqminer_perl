package varDB::Config;

our @ISA = qw/Exporter/;
our @EXPORT = qw/$VARDB_RELEASE $VARDB_HOME $VARDB_SEARCH_FILE 
	$VARDB_ORGANISM_FILE $UNIPROTDB $PDBDB $HMMDB $GENOMEDB $PFAM_VERSION
	$DEBUG $VARDB_COMMIT_DIR $HMMERPARAM $WISEPARAM/;

our $VARDB_RELEASE = 1;
our $DEBUG = 1;

our $VARDB_HOME = "/Volumes/Data/projects/vardb";
our $VARDB_SEARCH_FILE = "$VARDB_HOME/etc/config_search.txt";
our $VARDB_ORGANISM_FILE = "$VARDB_HOME/etc/config_organism.txt";
our $VARDB_COMMIT_DIR = "$VARDB_HOME/svn/web/data/diego/";


our $UNIPROTDB = "$VARDB_HOME/db/uniprot";
our $PDBDB = "$VARDB_HOME/db/pdb";
our $HMMDB = "$VARDB_HOME/db/pfam";
our $PFAM_VERSION = "pfam-22";
our $GENOMEDB = "$VARDB_HOME/db/genomes";

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