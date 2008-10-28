package varDB::NCBI::Paper;

use strict;
use warnings;
use varDB::Config;
use varDB::ItemSet::Item;
use vars qw( @ISA );
@ISA = ("varDB::ItemSet::Item");

sub new {
	my $class = shift;
	
	my $self = {};
	
	bless $self, $class;
    $self->_initialize(@_);
    return $self;
}

sub _initialize {
	my $self = shift;
	
	my $basedir = "$VARDB_MINING_DIR/vardb-$VARDB_RELEASE/";
	$basedir = "$VARDB_MINING_DIR/last/" if $DEBUG == 1;
	$basedir .= "paper";
	$self->{basedir} = $basedir;
}

# scan a given paper for nucleotide sequences.
sub scan {
	my $self = shift;
	my $db = $self->database;
	
	$self->debug;
	return 1;
	my $id = $self->id;

	use Bio::DB::EUtilities;
	
	my $factory = new Bio::DB::EUtilities(
		-eutil => 'elink',
		-db => $db,
		-dbfrom => 'pubmed',
		-correspondence => 1,
		-id => [ $id ]
	);

	my @ids;
	while (my $ls = $factory->next_LinkSet) {
		# just interested in that link.
		next if $ls->get_linkname ne "pubmed_$db";
		print STDERR "* link_name: ",$ls->get_linkname,"\n";
		print STDERR "* query ids: ", join(" ", $ls->get_submitted_ids), "\n";
		my @tmp = $ls->get_ids;
		print STDERR "* number_links: ", scalar @tmp, "\n\n";
		push @ids, @tmp;
	}
	
	return @ids;
}

sub get_seqs {
	my $self = shift;
	my $ids = shift;

	my $db = $self->database;
	
	my $file = $self->id."-$db.gb";
	unlink $file;
	my @id = @{ $ids };
	
	my $count = scalar @id;
	my ($retmax, $retstart) = (500,0);
	my $retry = 0;
	print STDERR "|";
	RETRIEVE_SEQS:
	while ($retstart < $count) {
		my @subid = _subset(\@id, $retstart, $retmax);
		my $factory = new Bio::DB::EUtilities(-eutil => 'efetch',
		-rettype => 'genbank', -id => \@subid,	-db => $db);
		eval{
			print STDERR "=";
			$factory->get_Response(-file => ">>$file");
		};
		if ($@) {
			die "[ERROR] server error: $@.  try again later" if $retry == 5;
			print STDERR "[ERROR] server error, redo #$retry\n";
			$retry++ && redo RETRIEVE_SEQS;
		}
		$retstart += $retmax;
	}
	print STDERR "| OK\n";
}

sub ortholog {
	my $self = shift;
	$self->{ortholog} = shift if @_;
	return $self->{ortholog};
}

sub database {
	my $self = shift;
	$self->{database} = shift if @_;
	return $self->{database};
}

sub debug {
	my $self = shift;
	
	print STDERR "# SCAN INFO\n";
	print STDERR "* paper: [", $self->id, "]\n";
	print STDERR "* database: ", $self->database, "\n";
	foreach my $ortholog ($self->ortholog->item_list) {
		print STDERR "* ortholog: ", $ortholog->id, "\n";
		print STDERR "* hmm: ", $ortholog->hmm, "\n";
		print STDERR "+\n"
	}
	print STDERR "* base_dir: $self->{basedir}\n";
	print STDERR "\n";
}

sub _subset {
	my $ids = shift;
	my $s = shift;
	my $m = shift;
	
	my @id = @{ $ids };
	my $l = scalar @id;
	if ($s + $m > $l) {
		return @id[$s .. ($l-1)];
	} else {
		return @id[$s .. ($s+$m-1)];
	}
}

sub filter {
	my $self = shift;
	my $id = $self->id;
	
	my @ortholog = $self->ortholog->item_list; # this is for the filters.
	#print STDERR "* orthologs: ", scalar @ortholog, "\n";
}

1;