#!/usr/bin/env perl
#
#  This is the main script for parsing data comming from NCBI sequence sets
#  i.e. sequences comming from papers. This parser is meant to be used with
#  Genbank file formats. This script generates several files for each gene
#  family-organism combination plus the dataset name (by default, the first
#  author's surname in the publication). It also generates the file 'skip.log'
#  with all the skipped entries.
#
#
use strict;
use warnings;
use Bio::SeqIO;
use Getopt::Long;
# Fix: deprecated module, use TaxonSet instead.
use SeqMiner::Config::Param;

my %O;
GetOptions(\%O, 'i:s', 'd:s');

my $help = <<"HELP";

#!! WARNING !!
#  This is the main script for parsing data comming from NCBI sequence sets
#  i.e. sequences comming from papers. This parser is meant to be used with
#  Genbank file formats. This script generates several files for each gene
#  family-organism combination plus the dataset name (by default, the first
#  author's surname in the publication). It also generates the file 'skip.log'
#  with all the skipped entries.
#!! WARNING !!

    vardb_gbset_parse.pl -i <file>

HELP

die $help if !exists $O{i};

# TODO: this should be done automatically (i.e. parsing the reference line)?
my $setname = $O{i};
$setname =~ s/\.gb$//;

my $date = localtime;
open SKIP, ">>skip".&SeqMiner::Config::Param::_get_random_dir()."log";
print SKIP "## Running time: $date ##\n";
print SKIP "* set name: $setname\n";

my $in = new Bio::SeqIO(-file => $O{i}, -format => 'genbank');

my @TRUSTED_PAPERS = ();
my %TRUSTED_ANNOTATIONS = (
	"pfemp1" => "var",
	"emp1" => "var",
	"erythrocyte membrane protein 1" => "var",
	"var" => "var",
	"DBLalpha" => "var",
	"rif" => "rifin_stevor",
	"rifin" => "rifin_stevor",
	"stevor" => "rifin_stevor",
	"major surface glycoprotein" => "msg",
	"msg" => "msg",
);
# store file handlers.
my %FH = ();

while (my $seq = $in->next_seq) {
    # parse annotations, in particular reference line:
	my $ac = $seq->annotation;
    my @refs = $ac->get_Annotations('reference');
    my @pubmed;
	my $quality_checked = 0;
    foreach my $ref (@refs) {
        if (defined $ref->pubmed) {
            push @pubmed, $ref->pubmed;
			# !! TODO: check the list of trusted publications !!
        }
    }
    my $pubmed = join ";", @pubmed;

	my $family = "NOT_FOUND";
    my $isolate = "";
    my $isolation_source = "";
    my $country = "";
	my $translation = "";
	
	my @feat = $seq->get_SeqFeatures;
    foreach my $feat (@feat) {
		if ($feat->primary_tag eq "source") {
            if ($feat->has_tag('isolate')) {
                ($isolate) = $feat->get_tag_values('isolate');
            }
            if ($feat->has_tag('isolation_source')) {
                ($isolation_source) = $feat->get_tag_values('isolation_source');
            }
            if ($feat->has_tag('country')) {
                ($country) = $feat->get_tag_values('country');
            }
        }
        if ($feat->primary_tag eq "CDS") {
            if ($feat->has_tag('translation')) {
                ($translation) = $feat->get_tag_values('translation');
            }
			if (!$quality_checked and $feat->has_tag('note')) {
				$family = check_quality($feat->get_tag_values('note'));
				$quality_checked = 1 if ($family ne "NOT_FOUND");
			}
        }
		if ($feat->primary_tag eq "gene") {
			if (!$quality_checked and $feat->has_tag('gene')) {
				$family = check_quality($feat->get_tag_values('gene'));
				$quality_checked = 1 if ($family ne "NOT_FOUND");
			}
		}
    }
	
	# last resource...
	if (!$quality_checked) {
		$family = check_quality($seq->description);
		$quality_checked = 1 if ($family ne "NOT_FOUND");
	}
	
	if ($quality_checked) {
		my $orgb = lc $seq->species->binomial;
		$orgb =~ s/\s/\./;
		
		# check if there is a fh available.
		if (! exists $FH{$family}) {
			$FH{$family} = create_fh($family, $orgb, $setname);
		}
		my $fh = $FH{$family};
		print $fh
			$seq->display_id, "\t",
			$orgb.".".$family, "\t",
			$orgb.".".$seq->species->ncbi_taxid, "\t",
			$isolate, "\t",
			$isolation_source, "\t",
			$country, "\t",
			$pubmed, "\t",
			$translation, "\t",
			$seq->seq, "\t",
			$seq->description, "\n";
	} else {
		print SKIP "  - sequence: ", $seq->display_id, " '", $seq->description, "'\n";
	}
}

# close all open FH.
foreach my $fh (values %FH) {
	close $fh;
}
close SKIP;

sub create_fh {
	my ($family, $organism, $set) = @_;
	$organism =~ s/(.).+(\..+)/$1$2/;
	open FH, ">$family-$organism\_$set.txt" or die "cannot open file $!\n";
	print FH "SEQUENCE\tfamily\tgenome\tisolate\tisolation_source\tcountry\tpubmed\ttranslation\tsequence\tdescription\n";
	return *FH;
}

sub check_quality {
	my $ann = lc shift;
	foreach my $key (keys %TRUSTED_ANNOTATIONS) {
		if ($ann =~ /$key/) {
			return $TRUSTED_ANNOTATIONS{$key};
		}
	}
	return "NOT_FOUND";
}