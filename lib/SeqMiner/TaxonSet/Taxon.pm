package SeqMiner::TaxonSet::Taxon;

=head1 MAIN

SeqMiner::TaxonSet::Taxon

Methods working at taxon level allowing various task to be performed. Mainly is used for
maintaining taxon information and downloading data from specific repositories. Filtering
and formating is also performed in this module.

=cut

use strict;
use warnings;
use SeqMiner::FamilySet;
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

	$self->{genus} = undef;
	$self->{species} = undef
	$self->{strain} = undef;
	$self->{family} = new SeqMiner::FamilySet;
	$self->{type} = undef;
	$self->{source} = undef;
}

sub name {
	my $self = shift;
	if ($self->strain ne "_undef_") {
		return $self->genus.".".$self->species."_".$self->strain;
	} else {
		return $self->genus.".".$self->species;
	}
}

sub binomial {
	my $self = shift;
	$self->genus =~ /^(.{1})/;
	return $1.".".$self->species;
}

sub organism {
	my $self = shift;
	my $org = $self->genus.".".$self->species;
	$org .= "_".$self->strain if defined $self->strain;
	return $org;
}

sub dir {
	my $self = shift;
	if (defined $self->strain) {
		return $self->binomial."_".$self->strain;
	} else {
		return $self->binomial;
	}
}

sub key {
	my $self = shift;
	my $key = $1 if $self->genus =~ /^(.{1})/;
	$key .= $1 if $self->species =~ /^(.{2})/;
	return $key."_".$self->strain;
}

sub genus {
	my $self = shift;
	$self->{genus} = shift if @_;
	return $self->{genus};
}

sub species {
	my $self = shift;
	$self->{species} = shift if @_;
	return $self->{species};
}

sub strain {
	my $self = shift;
	$self->{strain} = shift if @_;
	return $self->{strain};
}

sub type {
	my $self = shift;
	$self->{type} = shift if @_;
	return $self->{type};
}

sub source {
	my $self = shift;
	$self->{source} = shift if @_;
	return $self->{source};
}

sub seed {
	my $self = shift;
	$self->{seed} = shift if @_;
	return $self->{seed};
}

sub family {
	return shift->{family};
}

sub download {
	my $self = shift;
	
	$self->type eq "isolate" && do { $self->_download_isolate(@_); };
	$self->type eq "genome" && do { $self->_download_genome(@_); };
}

sub _download_isolate {
	my $self = shift;
	my $db = shift;
	
	my $id = _fix_taxid($self->id);	
	my $outdir = "$VARDB_HOME/db/genbank/".$self->name;
	my $file = $TARGET_DB{$db}.".gb";
	
	print STDERR "# DOWNLOAD\n";
	print STDERR "* db: $db\n";
	print STDERR "* file: $file\n";
	print STDERR "* outdir: $outdir\n\n";
	
	if (! -d $outdir) {
		mkdir $outdir;
	}
	chdir $outdir;
	unlink $file;
	
	use Bio::DB::EUtilities;

	print STDERR "* downloading [$db]: $id\n";
	my $factory = new Bio::DB::EUtilities (
		-eutil => 'esearch',
		-term  => $id,
		-db => $db,
		-usehistory => 'y',
		-verbose => -1
	);
	
	my $count = $factory->get_count;
	print STDERR "* count: $count\n";
	if ($count > 0) {
		my $hist = $factory->next_History || die 'No history data returned';
		$factory->set_parameters(
			-eutil => 'efetch',
			-rettype => 'genbank',
			-history => $hist
		);
		
		my ($retmax, $retstart) = (500, 0);
		my $retry = 0;
		RETRIEVE_SEQS:
		while ($retstart < $count) {
			$factory->set_parameters(-retmax => $retmax,
									-retstart => $retstart);
			eval{
				my $ret = $retstart + $retmax;
				$ret = $count if $ret > $count;
				printf STDERR "\r* progress: %.1f%s [%i]",
					100 * $ret/$count, "%", $ret;
				$factory->get_Response(-file => ">>$file");
			};
			if ($@) {
				die "Server error: $@.  Try again later" if $retry == 5;
				print STDERR "Server error, redo #$retry\n";
				$retry++ && redo RETRIEVE_SEQS;
			}
			$retstart += $retmax;
		}
		print STDERR "\n\n";
	
		my $outdir1 = $outdir;
		my $outdir2 = "$VARDB_HOME/db/isolate/".$self->name;
		
		&_seq_filter($outdir, $outdir1, $outdir2, $TARGET_DB{$db});
		&_seq_format($outdir, $TARGET_DB{$db});
		print STDERR "\n";
	} else {
		print STDERR "** NO SEQUENCES FOUND **\n\n";
	}
}

sub _seq_filter {
	my $dir = shift;
	my $outdir1 = shift;
	my $outdir2 = shift;
	my $file = shift;
	
	my $filter = 0;
	
#	my %FILTER = ();
#	open IN, "$VARDB_FILTER_FILE" or die "$!";
#	while (<IN>) {
#		next if /^#/;
#		chomp;
#		my ($source, $pubmed, $title, $keywords) = split '\t', $_;
#		push @{ $FILTER{'SOURCE'} }, $source if defined $source;
#		push @{ $FILTER{'PUBMED'} }, $pubmed if defined $pubmed;
#		push @{ $FILTER{'TITLE'} }, $title if defined $title;
#		push @{ $FILTER{'KEYWORDS'} }, $keywords if defined $keywords;
#	}
#	close IN;
		
	# TODO: move project files to another place.
	print STDERR "* filtering ... ";
	open OUT1, ">$outdir1/$file.project.gb" or die "$!";
	open OUT2, ">$outdir2/$file.gb" or die "$!";
	open IN, "$dir/$file.gb" or die "$!";
	while (<IN>) {
		if (/^LOCUS/) {
			$a .= $_;
			while (<IN>) {
				$a .= $_;
				$filter = 1 if /^PROJECT/;
				#if (/\s+?TITLE\s+(.+)/) {
				#	$filter = 1 if $1 =~ /The genome sequence/;
				#}
				
				if (/^DEFINITION\s+(.+)/) {
					$filter = 1 if _check_filter($1);
				}
				
				if (/^KEYWORDS\s+(.+)/) {
					$filter = 1 if _check_filter($1);
				}
				
				if (/^\/\//) {
					# check project.
					if ($filter == 1) {
						# print.
						print OUT1 $a;
					} else {
						# print.
						print OUT2 $a;
					}
					# reset.
					$filter = 0;
					$a = "";
					last;
				}
			}
		}
	}
	close IN;
	close OUT1;
	close OUT2;
	print STDERR "OK\n";
}

sub _check_filter {
	my $line = shift;
	
	my @filter = (
		"complete genome",
		"complete mitochondrial genome",
	);
	
	foreach my $filter (@filter) {
		return 1 if $line =~ /$filter/;
	}
	return 0;
}

sub _check_title {
	my $line = shift;
	my @title = @{ (shift) };
	return 0 if $line eq "Direct Submission";
	#print STDERR "begin check\n";
	#print STDERR "checking: #$line#\n";
	#print STDERR "and: @title\n";
	foreach my $title (@title) {
		return 1 if $title eq $line;
	}
	return 0;
}

sub _check_pubmed {
	my $line = shift;
	my @pubmed = @{ (shift) };
	foreach my $pubmed (@pubmed) {
		my @refs = split ";", $pubmed;
		foreach my $ref (@refs) {
			return 1 if $ref eq $line;
		}
	}
	return 0;
}

sub _seq_format {
	my $dir = shift;
	my $basename = shift;
	
	
	my $infile = "$basename.gb";
	#print STDERR "format: $infile\n";
		
	my $outfile = "$basename.fa";
	
	use Bio::SeqIO;
	
	my $in = new Bio::SeqIO(-file => "$infile", -format => 'genbank');
	my $out = new Bio::SeqIO(-file => ">$outfile", -format => 'fasta');

	print STDERR "* formatting ... ";
	open OUT, ">$basename.skip" or die "$!";
	while (my $seq = $in->next_seq) {
		if (defined $seq->seq) {
			$out->write_seq($seq);
		} else {
			print OUT $seq->display_id, "\n";
		}
	}
	close OUT;
	
	system "formatdb -i $outfile -n $basename -p F -o T -V";
	print STDERR "OK\n";
}

sub _fix_taxid {
	return "txid".(shift)."[Organism:exp]";
}

sub _download_genome {
	my $self = shift;
	
	$self->source eq "plasmodb" && do
	{
		$self->_download_eupathdb;
	};
	
	$self->source eq "giardiadb" && do
	{
		$self->_download_eupathdb;
	};
	
	$self->source eq "ncbi" && do
	{
		$self->_download_refseq;
	};
	
}

sub _download_refseq {
	my $self = shift;
	my $db = 'genome';
	my $file = $self->organism.".gb";

	my $id = _fix_taxid($self->id);	
	my $outdir = "$VARDB_HOME/db/ncbi/".$self->binomial."_".$self->strain;
	
	print STDERR "# DOWNLOAD\n";
	print STDERR "* db: $db\n";
	print STDERR "* file: $file\n";
	print STDERR "* outdir: $outdir\n\n";
	
	if (! -d $outdir) {
		mkdir $outdir;
	}
	chdir $outdir;
	unlink $file;
	
	use Bio::DB::EUtilities;

	print STDERR "* downloading [$db]: $id\n";
	my $factory = new Bio::DB::EUtilities (
		-eutil => 'esearch',
		-term  => $id,
		-db => $db,
		-usehistory => 'y',
		-verbose => -1
	);

	my $count = $factory->get_count;
	print STDERR "* count: $count\n";
	if ($count > 0) {
		my $hist = $factory->next_History || die 'No history data returned';
		$factory->set_parameters(
			-eutil => 'efetch',
			-rettype => 'genbank',
			-history => $hist
		);
		
		my ($retmax, $retstart) = (500, 0);
		my $retry = 0;
		RETRIEVE_SEQS:
		while ($retstart < $count) {
			$factory->set_parameters(-retmax => $retmax,
									-retstart => $retstart);
			eval{
				my $ret = $retstart + $retmax;
				$ret = $count if $ret > $count;
				printf STDERR "\r* progress: %.1f%s [%i]",
					100 * $ret/$count, "%", $ret;
				$factory->get_Response(-file => ">>$file");
			};
			if ($@) {
				die "Server error: $@.  Try again later" if $retry == 5;
				print STDERR "Server error, redo #$retry\n";
				$retry++ && redo RETRIEVE_SEQS;
			}
			$retstart += $retmax;
		}
		print STDERR "\n\n";
		
		$outdir = "$VARDB_HOME/db/genomes/".$self->binomial."_".$self->strain;
		if (! -d $outdir) {
			mkdir $outdir;
		}
		system "vardb_ncbi_parse.pl -i $file -d $outdir";
		chdir "$outdir";
		system "vardb_process_directory.sh";
		
		print STDERR "\n";
	} else {
		print STDERR "** NO SEQUENCES FOUND **\n\n";
	}
}

my %EUPATHDB_RELEASE = (
	plasmodb  => "5.5",
	giardiadb => "1.1",
);

my %EUPATHDB_MIRRORS = (
	plasmodb  => "http://www.plasmodb.org/common/downloads/release-",
	giardiadb => "http://giardiadb.org/common/downloads/release-",
);


sub _download_eupathdb {
	my $self = shift;
	
	my $release = $EUPATHDB_RELEASE{$self->source};
	my $org = $self->binomial;
	$org =~ s/\.//;
	$org =~ s/(.)/\u$1/;
	print STDERR "* short name: $org\n";
	my $source = $self->source;
	$source =~ s/(.)(.+)db/\u$1$2DB/;
	my $file = "$org\_$source-$release.gff";
	#my $url = "http://www.plasmodb.org/common/downloads/release-$release/$org/$file";
	my $url = $EUPATHDB_MIRRORS{$self->source}."$release/$org/$file";
	print STDERR "* url: $url\n";
	
	use LWP::UserAgent;
	my $ua = new LWP::UserAgent;
	$ua->agent("SeqMiner");
	
	print STDERR "* downloading $file ... ";
    my $req = new HTTP::Request(GET => $url);
    my $res = $ua->request($req);
    if ($res->is_success) {
		print STDERR "OK\n";
		my $dir = "$VARDB_HOME/db/eupathdb/".$self->binomial."_".$self->strain;
		print STDERR "* outdir: $dir\n";
        print STDERR "* writting $org file ... ";
		chdir $dir;
        open OUT, ">$file";
        print OUT $res->content;
        close OUT;
		print STDERR "OK\n\n";
		
		# processing;
		my $outdir = "$VARDB_HOME/db/genomes/".$self->binomial."_".$self->strain;
		chdir "$outdir";
		system "vardb_eupathdb_parse.pl -i $dir/$file";
		system "vardb_process_directory.sh";
		print STDERR "\n";
    } else {
		print STDERR "ERROR\n";
        print STDERR $res->status_line, "\n\n";
    }
}

sub debug {
	my $self = shift;
	print STDERR "* taxon: ", $self->id, "\n";
	print STDERR "* genus: ", $self->genus, "\n";
	print STDERR "* species: ", $self->species, "\n";
	print STDERR "* strain: ", $self->strain, "\n";
	print STDERR "* type: ", $self->type, "\n";
	print STDERR "* source: ", $self->source, "\n\n";
}

1;