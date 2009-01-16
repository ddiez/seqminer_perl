#!/usr/bin/env perl

use strict;
use warnings;
use SeqMiner::Config;
use SeqMiner::Downloader::Uniprot;

my $uniprot = new SeqMiner::Downloader::Uniprot();
$uniprot->debug; # show config information.
#$uniprot->download;

# retrieve release info.
# my $rel = new SeqMiner::Downloader({
		# mirror  => $MIRROR,
		# file    => $release,
		# outdir  => '.',
		# outfile => $release,
		# id      => 'uniprot',
# });
# $rel->execute;
# 
# open IN, "$release" or die "$!\n";
# $rel = <IN>;
# chomp $rel;
# close IN;
# $rel =~ s/.+Release (.+) consist.+/$1/;
# my $outdir = "uniprot-$rel";
# if (-d $outdir) {
	# print STDERR "directory $outdir exists, skipping ...\n";
# } else {
	# mkdir $outdir;
	# rename $release, "$outdir/$release";
	# chdir $outdir;
# }
# 
# my @filetypes = keys %FILE;
# @filetypes = sort @filetypes;
# foreach my $filetype (@filetypes) {
	# # download files.
	# my $updater = new SeqMiner::Downloader({
		# mirror  => $MIRROR,
		# file    => $FILE{$filetype},
		# outdir  => ".",
		# outfile => $FILE{$filetype},
		# id      => 'uniprot',
		# gunzip  => $GUNZIP{$filetype},
		# pindex  => $PINDEX{$filetype},
		# ptype   => $PTYPE{$filetype},
	# });
	# my $res = $updater->execute;
	# if ($res) {
	# }
# }
