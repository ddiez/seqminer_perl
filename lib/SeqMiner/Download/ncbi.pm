package SeqMiner::Download::ncbi;

use base qw(SeqMiner::Download);

sub download {
	my $self = shift;
	print STDERR "parser for ncbi!\n";
}

sub download_by_taxon {
	my $self = shift;
	my $id = shift;
	my $db = shift;

	$id = _fix_taxid($id);
	my $outdir = ".";
	my $file = "foo.gb";

	print STDERR "# DOWNLOAD\n";
	print STDERR "* db: $db\n";
	print STDERR "* file: $file\n";
	print STDERR "* outdir: $outdir\n\n";

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

        #my $outdir1 = $outdir;
        #my $outdir2 = "$SM_HOME/db/isolate/".$self->name;

        #&_seq_filter($outdir, $outdir1, $outdir2, $TARGET_DB{$db});
        #&_seq_format($outdir, $TARGET_DB{$db});
        print STDERR "\n";
    } else {
		print STDERR "** NO SEQUENCES FOUND **\n\n";
    }
}

sub _fix_taxid {
    return "txid".(shift)."[Organism:exp]";
}


1;
