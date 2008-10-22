package varDB::NCBI::Paper;

use strict;
use warnings;
use varDB::Config;

sub new {
	my $class = shift;
	
	my $self = {};
	
	bless $self, $class;
    $self->_initialize(@_);
    return $self;
}

sub _initialize {
	my $self = shift;
	
	open IN, "$VARDB_PAPER_FILE" or die "$!";
	while (<IN>) {
		next if /^[#|\n|taxon_id]/;
		chomp;
		my ($taxon_id, $ortholog, $family, $id) = split '\t', $_;
		push @{ $self->{$taxon_id}->{$ortholog}->{$family} }, $id;
	}
	close IN;
}

# scan all papers in a Paper object.
sub scan_all {
	my $self = shift;
	foreach my $taxon (keys %{$self}) {
		foreach my $ortholog (keys %{ $self->{$taxon} }) {
			foreach my $family (keys %{ $self->{$taxon}->{$ortholog} }) {
				foreach my $id (@{ $self->{$taxon}->{$ortholog}->{$family} }) {
					$self->scan($id);
				}
			}
		}
	}
}

# scan a given paper for nucleotide sequences.
sub scan {
	my $self = shift;
	my $id = shift;
	my $db = shift;
	
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
	my $db = shift;
	my $file = shift;
	
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

1;