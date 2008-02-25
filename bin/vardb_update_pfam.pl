#!/usr/bin/env perl

use strict;
use warnings;
use varDB::Downloader::Pfam;

# retrieve release info.
my $rel = new varDB::Downloader({
		mirror  => $MIRROR,
		file    => $release,
		outdir  => '.',
		outfile => $release,
		id      => 'pfam',
});
$rel->execute;

open IN, "$release" or die "$!\n";
$rel = <IN>;
chomp $rel;
close IN;
$rel =~ s/.+Release (.+) consist.+/$1/;
my $outdir = "pfam-$rel";
if (-d $outdir) {
	print STDERR "directory $outdir exists, skipping ...\n";
} else {
	mkdir $outdir;
	rename $release, "$outdir/$release";
	chdir $outdir;
}

my @filetypes = keys %FILE;
@filetypes = sort @filetypes;
foreach my $filetype (@filetypes) {
	# download files.
	my $updater = new varDB::Downloader({
		mirror  => $MIRROR,
		file    => $FILE{$filetype},
		outdir  => ".",
		outfile => $FILE{$filetype},
		id      => 'pfam',
		gunzip  => $GUNZIP{$filetype},
		pindex  => $PINDEX{$filetype},
		ptype   => $PTYPE{$filetype},
	});
	my $res = $updater->execute;
	if ($res) {
	}
}
