#!/usr/bin/env perl

use strict;

use Bio::SeqIO;
use varDB::Config;

# store regexps for different promoters.
my %promoters = (
	"stop.0"   => "TAG",
	"stop.1"   => "TGA",
	"stop.2"   => "UTT",
	"start.0"  => "ATG",
	"start.1"  => "GTG",
	"start.2"  => "TTG",
	"p10.0"    => "TATAAT",
	"p10.1"    => "TA.A.T",
	"p10.2"    => "TA.[A|T].T",
	"p10.3"    => "TA...T",
	"p10.4"    => "[T|A]A...T",
	"p10.5"    => "[T|A][A|T]...[T|A]",
	"p10.6"    => ".[A|T]...[T|A]",
	"p10ext.0" => "TG.TATAAT",
	"p35.0"    => "TTGACA",
	"p35.1"    => "TTGA..",
	"p35.2"    => "TT[G|C][A|T]..",
	"p35.3"    => "TT....",
	"p35.4"    => "[T|A][T|A][G|C][A|T]..",
	"p35.5"    => "[T|A][T|A][G|C]...",
	"p35.6"    => "[T|A][T|A]....",
);
my @motifs = sort keys %promoters;

my $DB = $varDB::Config::GENOMEDB;

# read in parameters.
my $org = shift;
my $gene = shift;
my $offset = shift;

# setup dir/files.
my $indir = "$DB/$org";
my $genome = "$indir/$org-genome.fa";
my $pos = "$indir/$org-position.txt";

# read genome.
my $in = new Bio::SeqIO(-file => $genome);
my $seq = $in->next_seq;
my $gl = $seq->length;

# read position information.
my %symbol;
my %fpos;
my %pos;
open IN, "$pos";
while (<IN>) {
	chomp;
	my @line = split '\t', $_;
	$symbol{$line[0]} = $line[1];
	$fpos{$line[0]} = $line[2];
	$pos{$line[0]} = $line[3];
}
close IN;

die "Error: no gene $gene found in $pos\n" if !exists $pos{$gene};

my $mypos = $pos{$gene};
my $strand = 0;
print STDERR "DEBUG: $mypos\n";

# search in the - strand.
if ($mypos =~ /complement\((.+)\)/) {
	$mypos = $1;
	$strand = 1;
	print STDERR "strand: -\n";
	die "no implemented yet.";
} else {
	print STDERR "strand: +\n";
}


my @pos = split '\.\.', $mypos;
print STDERR "pos: @pos\n";
my $genel = $pos[1] - $pos[0] + 1;
print STDERR "length: $genel\n";

$offset = 100 if !defined $offset;
print STDERR "offset: $offset\n";
$pos[0] -= $offset;
$pos[1] += $offset;

# TODO: allow for circular genomes.
#$pos[0] = 1 if $pos[0] < 1;
#$pos[1] = $gl if $pos[1] > $gl;

my $slice = $seq->subseq($pos[0], $pos[1]);
#$slice =~ tr/agtcAGTC/tcagTCAG/ if $strand;
#$slice =~ /(.{$offset})(.+)(.{$offset})/;
#print STDERR "$1 > $2 < $3\n";

# search for promoter sequences.
my %search;
my %motif;
foreach my $key (@motifs) {
	# search motif.
	my $promoter = $promoters{$key};
	#$promoter = $promoters{'p35.1'};
	#$promoter =~ tr/agtcAGTC/tcagTCAG/ if $strand;

	print STDERR "regexp: $promoter\n";

	my @pos0;
	my @pos1;
	while ($slice =~ /($promoter)/g) {
		my $match = $1;
		my $l = length $match;
		my $x1 = pos $slice;
		my $x0 = $x1 - $l + 1;
		if ($key =~ /start/ || $key =~ /stop/) {
			push @pos0, $x0;
			push @pos1, $x1;
			print STDERR "match: $match ($x0, $x1)\n";
		} else {
			if ($x1 <= $offset) { 
				push @pos0, $x0;
				push @pos1, $x1;
				print STDERR "match: $match ($x0, $x1)\n";
			} else {
				print STDERR "match: $match ($x0, $x1) [discarded: inside gene]\n";
			}
		}
	}
	print STDERR "\n";
	$search{$key} = [@pos0, @pos1];

	# create motif sequence.
	my $slicet = $slice;
	$slicet =~ s/./\./g;
	my @slicet = split "", $slicet;
	foreach my $n (0 .. $#slicet) {
		if ($n == $offset) {
			$slicet[$n] = ">";
		}
		if ($n == $genel + $offset) {
			$slicet[$n] = "<";
		}
		foreach my $k (0 .. $#pos0) {
			if ($n >= $pos0[$k] - 1 && $n <= $pos1[$k] - 1) {
				$slicet[$n] = "*";
			}
		}
	}
	$slicet = join "", @slicet;
	$motif{$key} = $slicet;
}

# reformat.
$slice =~ s/(.{60})/$1\n/g;
# pretty print.
my @tmp1 = split '\n', $slice;

foreach my $n (0 .. $#tmp1) {
	printf "%12s: ", $gene;
	print "$tmp1[$n]\n";
	
	#foreach my $key (keys %motif) {
	foreach my $key (@motifs) {
		my $slicet = $motif{$key};
		$slicet =~ s/(.{60})/$1\n/g;
		my @tmp2 = split '\n', $slicet;

		printf "%12s: ", "$key";
		print "$tmp2[$n]\n";
	}
	print "\n";
}
