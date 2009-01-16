#!/usr/bin/env perl
# retrieve fasta files of proteins.

use strict;
use warnings;
use LWP::UserAgent;
use Getopt::Long;

use SeqMiner::Config;
use SeqMiner::KEGG;

#my $GENOMEDB = $SeqMiner::Config::GENOMEDB;

my $help = <<HELP;

  This script install the KEGG genomes supported in SeqMiner in the kegg direc-
tory. If the directory exists, skyp the step, unless the -f option is passed.
In that case, the old directory is renamed and a new one is created.

HELP

my %O;
GetOptions(\%O, 'f');
my $force = 0;
$force = 1 if defined $O{f};

my $ua = new LWP::UserAgent;
$ua->agent("SeqMiner/0.1");

# file extensions.
my %IN_EXT = (
	'protein'    => 'pep',
	'nucleotide' => 'nuc',
	'genome'     => 'genome',
	'position'   => 'pos',
);

##
my %OUT_EXT = (
	'protein'    => 'fa',
	'nucleotide' => 'fa',
	'genome'     => 'fa',
	'position'   => 'txt',
);

# create index file?
my %INDEX = (
	'protein'    => 1,
	'nucleotide' => 1,
	'genome'     => 1,
	'position'   => 0,
);

# format file with formatdb?
my %FORMATDB = (
	'protein'    => 1,
	'nucleotide' => 1,
	'genome'     => 1,
	'position'   => 0,
);

# check if output directory is there.
if (! -d $GENOMEDB) {
	mkdir $GENOMEDB;
} 
chdir $GENOMEDB;

LOOP:
foreach my $org (keys %ORGS) {
	if (-d $org) {
		if ($force) {
			my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) =
				localtime time;
			my $org_old = $org."_$sec$min$hour$mday$mon$year";
			print "renaming $org to $org_old\n";
			rename $org, $org_old;
		} else {
			print "skipping $org\n";
			next LOOP;
		}
	}
	mkdir "$org";
	chdir "$org";
	foreach my $filetype (keys %IN_EXT) {
		my $infile = "$ORGS{$org}.$IN_EXT{$filetype}";
		my $url = $KEGG_MIRROR.$KEGG_GENOME.$org."/".$infile;

		print "trying $org/$infile\n";
		my $req = HTTP::Request->new(GET => $url);
		my $res = $ua->request($req);
		if ($res->is_success) {	
			my $outfile = "$org-$filetype.$OUT_EXT{$filetype}";
			
			print "writting $outfile file\n";
			open OUT, ">$outfile";
			print OUT $res->content;
			close OUT;

			# index for perl.
			if ($INDEX{$filetype}) {
				my $idxfile = "$org-$filetype.idx";
				unlink $idxfile;
				system "index_fasta.pl $outfile $idxfile";
			}

			# index for blast.
			if ($FORMATDB{$filetype}) {
				my $type = "F";
				$type = "T" if $IN_EXT{$filetype} eq "pep"; 
				system "formatdb -t $org-$filetype -n $org-$filetype \\
					-p $type -i $outfile";
			}
		} else {
			print $res->status_line, "\n";
		}
	}
	chdir "..";
}
