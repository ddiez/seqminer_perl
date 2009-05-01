use SeqMiner::Download;

my $d = new SeqMiner::Download("ncbi");
$d->download_by_taxon("185431", "genome");
