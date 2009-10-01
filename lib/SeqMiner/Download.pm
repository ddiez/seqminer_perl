package SeqMiner::Download;

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
	$self->id(shift);
	$self->{taxon} = undef;
}

sub taxon {
	my $self = shift;
	$self->{taxon} = shift if @_;
	return $self->{taxon};
}

sub source {
	return shift->taxon->source;
}

sub type {
	return shift->taxon->type;
}

sub dir {
	return shift->organism;
}

#sub download {
#	my $self = shift;
#	
#	$self->type eq "isolate" && do { $self->_download_isolate(@_); };
#	$self->type eq "genome" && do { $self->_download_genome(@_); };
#}
#
#sub _download_isolate {
#	my $self = shift;
#	my $db = shift;
#	
#	my $outdir = "$SM_HOME/db/genbank/".$self->name;
#	#my $outdir2 = "$SM_HOME/db/isolate/".$self->name;
#	my $file = $TARGET_DB{$db}.".gb";
#	
#	if (! -d $outdir) {
#		mkdir $outdir;
#	}
#	chdir $outdir;
#	unlink $file;
#	
#	#if (! -d $outdir2) {
#	#	mkdir $outdir2;
#	#}
#	
#	use SeqMiner::Download::Driver;
#	my $down = new SeqMiner::Download::Driver("ncbi");
#	$down->outdir($outdir);
#	$down->filename($file);
#	#my $special = undef;
#	#$special = "babesia" if $self->id eq "484906";
#	return $down->download_by_taxon($self->id, $db);
#	
##	if ($count > 0) {
##		&_seq_filter($outdir1, $outdir2, $TARGET_DB{$db});
##		&_seq_format($outdir2, $TARGET_DB{$db});
##	} else {
##		print STDERR "## NO SEQUENCES FOUND\n\n";
##	}
#}
#
#sub filter {
#	my $self = shift;
#	
#	$self->type eq "isolate" && do { $self->_filter_isolate(@_); };
#	#$self->type eq "genome" && do { $self->_download_genome(@_); };
#}
#
## this are nasty manual filters to remove genome sequencing files
## from a set of downloaded Nuclotide Core/EST files.
#sub _check_filter {
#	my $line = shift;
#	
#	my @filter = (
#		"complete genome",
#		"complete mitochondrial genome",
#		"chromosome.+complete sequence",
#		"chromosome.+\\*\\*\\* SEQUENCING IN PROGRESS \\*\\*\\*"
#	);
#	
#	foreach my $filter (@filter) {
#		return 1 if $line =~ /$filter/;
#	}
#	return 0;
#}
#
#sub _filter_isolate {
#	my $self = shift;
#	my $db = shift;
#	
#	print STDERR "* filtering $db ... ";
#	
#	my $outdir1 = "$SM_HOME/db/genbank/".$self->organism;
#	my $outdir2 = "$SM_HOME/db/isolate/".$self->organism;
#	my $base = $TARGET_DB{$db};
#	my $filter = 0;
#
#	if (! -e "$outdir1/$base.gb") {
#		print STDERR "WARNING: file $base.gb not found.\n\n";
#		return 0;
#	}
#
#	open OUT1, ">$outdir1/$base.project.gb" or die "$!";
#	open OUT2, ">$outdir2/$base.gb" or die "$!";
#	open IN, "$outdir1/$base.gb" or die "$!";
#	while (<IN>) {
#		if (/^LOCUS/) {
#			$a .= $_;
#			while (<IN>) {
#				$a .= $_;
#				$filter = 1 if /^PROJECT/;
#				#if (/\s+?TITLE\s+(.+)/) {
#				#	$filter = 1 if $1 =~ /The genome sequence/;
#				#}
#				
#				if (/^DEFINITION\s+(.+)/) {
#					$filter = 1 if _check_filter($1);
#				}
#				
##				if (/^KEYWORDS\s+(.+)/) {
##					$filter = 1 if _check_filter($1);
##				}
#				
#				if (/^\/\//) {
#					# check project.
#					if ($filter == 1) {
#						# print.
#						print OUT1 $a;
#					} else {
#						# print.
#						print OUT2 $a;
#					}
#					# reset.
#					$filter = 0;
#					$a = "";
#					last;
#				}
#			}
#		}
#	}
#	close IN;
#	close OUT1;
#	close OUT2;
#	print STDERR "OK\n";
#	
#	$self->_seq_format($outdir2, $base);
#	print STDERR "\n";
#}
#
#sub _seq_format {
#	my $self = shift;
#	my $dir = shift;
#	my $basename = shift;
#	
#	chdir $dir;
#	
#	my $infile = "$basename.gb";
#	#print STDERR "format: $infile\n";
#		
#	my $outfile = "$basename.fa";
#	
#	use Bio::SeqIO;
#	
#	my $in = new Bio::SeqIO(-file => "$infile", -format => 'genbank');
#	my $out = new Bio::SeqIO(-file => ">$outfile", -format => 'fasta');
#
#	print STDERR "* extract FASTA ... ";
#	open OUT, ">$basename.skip" or die "$!";
#	while (my $seq = $in->next_seq) {
#		if (defined $seq->seq) {
#			$out->write_seq($seq);
#		} else {
#			print OUT $seq->display_id, "\n";
#		}
#	}
#	close OUT;
#	print STDERR "OK\n";
#	print STDERR "* format ... ";
#	system "formatdb -i $outfile -n $basename -p F -o T -V";
#	print STDERR "OK\n";
#}
#
#sub _download_genome {
#	my $self = shift;
#	
#	$self->source eq "plasmodb" && do
#	{
#		$self->_download_eupathdb;
#	};
#	
#	$self->source eq "giardiadb" && do
#	{
#		$self->_download_eupathdb;
#	};
#	
#	$self->source eq "ncbi" && do
#	{
#		my $file = $self->organism.".gb";
#		my $outdir = "$SM_HOME/db/ncbi/".$self->binomial."_".$self->strain;
#		
#		
#		use SeqMiner::Download::Driver;
#		my $down = new SeqMiner::Download::Driver("ncbi");
#		$down->outdir($outdir);
#		$down->filename($file);
#		my $special = undef;
#		$special = "babesia" if $self->id eq "484906";
#		my $count = $down->download_by_taxon($self->id, "genome", $special);
#	};
#	
#}
#
#sub _download_refseq {
#	my $self = shift;
#	my $db = 'genome';
#	my $file = $self->organism.".gb";
#
#	my $id = _fix_taxid($self->id);	
#	my $outdir = "$SM_HOME/db/ncbi/".$self->binomial."_".$self->strain;
#	
#	print STDERR "# DOWNLOAD\n";
#	print STDERR "* db: $db\n";
#	print STDERR "* file: $file\n";
#	print STDERR "* outdir: $outdir\n\n";
#	
#	if (! -d $outdir) {
#		mkdir $outdir;
#	}
#	chdir $outdir;
#	unlink $file;
#	
#	use Bio::DB::EUtilities;
#
#	print STDERR "* downloading [$db]: $id\n";
#	my $factory = new Bio::DB::EUtilities (
#		-eutil => 'esearch',
#		-term  => $id,
#		-db => $db,
#		-usehistory => 'y',
#		-verbose => -1
#	);
#
#	my $count = $factory->get_count;
#	print STDERR "* count: $count\n";
#	if ($count > 0) {
#		my $hist = $factory->next_History || die 'No history data returned';
#		$factory->set_parameters(
#			-eutil => 'efetch',
#			-rettype => 'genbank',
#			-history => $hist
#		);
#		
#		my ($retmax, $retstart) = (500, 0);
#		my $retry = 0;
#		RETRIEVE_SEQS:
#		while ($retstart < $count) {
#			$factory->set_parameters(-retmax => $retmax,
#									-retstart => $retstart);
#			eval{
#				my $ret = $retstart + $retmax;
#				$ret = $count if $ret > $count;
#				printf STDERR "\r* progress: %.1f%s [%i]",
#					100 * $ret/$count, "%", $ret;
#				$factory->get_Response(-file => ">>$file");
#			};
#			if ($@) {
#				die "Server error: $@.  Try again later" if $retry == 5;
#				print STDERR "Server error, redo #$retry\n";
#				$retry++ && redo RETRIEVE_SEQS;
#			}
#			$retstart += $retmax;
#		}
#		print STDERR "\n\n";
#		
#		$outdir = "$SM_HOME/db/genomes/".$self->binomial."_".$self->strain;
#		if (! -d $outdir) {
#			mkdir $outdir;
#		}
##		system "vardb_ncbi_parse.pl -i $file -d $outdir";
##		chdir "$outdir";
##		system "vardb_process_directory.sh";
#		system "sm_parse.pl -i $file -o $outdir -f ncbi";
#		
#		print STDERR "\n";
#	} else {
#		print STDERR "** NO SEQUENCES FOUND **\n\n";
#	}
#}
#
#my %EUPATHDB_RELEASE = (
#	plasmodb  => "5.5",
#	giardiadb => "1.1",
#	tritrypdb => "1.1",
#);
#
#my %EUPATHDB_MIRRORS = (
#	plasmodb  => "http://www.plasmodb.org/common/downloads/release-",
#	giardiadb => "http://giardiadb.org/common/downloads/release-",
#	tritrypdb => "http://tritrypdb.org/common/downloads/release-",
#);
#
#
#sub _download_eupathdb {
#	my $self = shift;
#	
#	my $release = $EUPATHDB_RELEASE{$self->source};
#	my $org = $self->binomial;
#	$org =~ s/\.//;
#	$org =~ s/(.)/\u$1/;
#	print STDERR "* short name: $org\n";
#	my $source = $self->source;
#	$source =~ s/(.)(.+)db/\u$1$2DB/;
#	my $file = "$org\_$source-$release.gff";
#	#my $url = "http://www.plasmodb.org/common/downloads/release-$release/$org/$file";
#	my $url = $EUPATHDB_MIRRORS{$self->source}."$release/$org/$file";
#	print STDERR "* url: $url\n";
#	
#	use LWP::UserAgent;
#	my $ua = new LWP::UserAgent;
#	$ua->agent("SeqMiner");
#	
#	print STDERR "* downloading $file ... ";
#    my $req = new HTTP::Request(GET => $url);
#    my $res = $ua->request($req);
#    if ($res->is_success) {
#		print STDERR "OK\n";
#		my $dir = "$SM_HOME/db/eupathdb/".$self->binomial."_".$self->strain;
#		print STDERR "* outdir: $dir\n";
#        print STDERR "* writting $org file ... ";
#		chdir $dir;
#        open OUT, ">$file";
#        print OUT $res->content;
#        close OUT;
#		print STDERR "OK\n\n";
#		
#		# processing;
#		my $outdir = "$SM_HOME/db/genomes/".$self->binomial."_".$self->strain;
#		chdir "$outdir";
#		system "sm_parse.pl -i $dir/$file -o . -f plasmodb";
#		#system "vardb_eupathdb_parse.pl -i $dir/$file";
#		#system "vardb_process_directory.sh";
#		print STDERR "\n";
#    } else {
#		print STDERR "ERROR\n";
#        print STDERR $res->status_line, "\n\n";
#    }
#}
#
sub debug {
	my $self = shift;
	print STDERR "#---", ref $self, "--->\n";
	print STDERR "* taxon: ", $self->taxon->name, "\n";
	print STDERR "* source: ", $self->taxon->source, "\n";
	print STDERR "\\\\\n";
}

1;
