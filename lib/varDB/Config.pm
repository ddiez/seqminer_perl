package varDB::Config;

our @ISA = qw/Exporter/;
our @EXPORT = qw/$VARDB_HOME $UNIPROTDB $PDBDB $HMMDB $GENOMEDB $PFAM_VERSION/;

our $VARDB_HOME = "/Volumes/Data/projects/vardb";

our $UNIPROTDB = "$VARDB_HOME/db/uniprot";
our $PDBDB = "$VARDB_HOME/db/pdb";
our $HMMDB = "$VARDB_HOME/db/pfam";
our $PFAM_VERSION = "pfam-22";
our $GENOMEDB = "$VARDB_HOME/db/genomes";

1;