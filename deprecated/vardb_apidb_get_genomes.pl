#!/usr/bin/env perl
# retrieve fasta files of proteins.
use strict;
use warnings;
use LWP::UserAgent;

use varDB::ApiDB;
use varDB::Config;

my $GENOMEDB = $varDB::Config::GENOMEDB;

my $ua=LWP::UserAgent->new;
$ua->agent("varDB/0.1");

foreach my $org (keys %ORGS) {
	mkdir "$org";
	chdir "$org";
	foreach my $ext (keys %EXT) {
		my $infile = "$ORGS{$org}.$ext";
		my $url = $KEGG_MIRROR.$KEGG_GENOME.$org."/".$infile;
		print "trying $org/$infile\n";
		my $req = HTTP::Request->new(GET => $url);
		my $res = $ua->request($req);
		if($res->is_success) {
			my $file = "$org-$EXT{$ext}.fa";
			print "writting $file file\n";
			open OUT, ">$file";
			print OUT $res->content;
			close OUT;

			# index for perl.
			if($INDEX{$ext}) {
				my $idxfile = "$org-$EXT{$ext}.idx";
				unlink $idxfile;
				system "index_fasta.pl $file $idxfile";
			}

			# index for blast.
			if($FORMATDB{$ext}) {
				my $type = "F";
				$type = "T" if($ext eq "pep"); 
				system "formatdb -t $org-$EXT{$ext} -n $org-$EXT{$ext} \\
					-p $type -i $file";
			}
		} else {
			print $res->status_line, "\n";
		}
	}
	chdir "..";
}
