#!/usr/bin/env perl

use strict;
use warnings;
use GD::Simple;

my $file = shift;
my $high = shift;

open IN, "$file" or die "$0: $!\n";

my @genes;
my %start;
my %end;
my %strand;
while (<IN>) {
	chomp;
	my @line = split "\t", $_;
	die "multiple exons not supported yet." if exists $start{$_line[0]};
	push @genes, $line[0];
	my @pos = parse($line[3]);
	$start{$line[0]} = $pos[0];
	$end{$line[0]} = $pos[1];
	$strand{$line[0]} = $pos[2];
	$max = $pos[1] if $pos[1] >= $max;
}
close IN;

if (defined $high) {
	open IN, "$high" or die "$0: $!\n";

	while (<IN>) {
		chomp;
		@line = split '\t', $_;
		$line[0] =~ /.+:(.+)/;
		$high{$1}++;
	}
	close IN;

}

#foreach my $gene (@genes) {
	#print "$gene\t$start{$gene}\t$end{$gene}\t$strand{$gene}\n";
#}
#print "$max\n";
$ymin = 0;
$ymax = 500;
$yd = $ymax - $ymin;
$xmin = 0;
$xmax = 4*640;
$xd = $xmax - $xmin;
$cmax = $xmax/4;
$r = $xmax/$max;
$rr = $cmax/$max;

$img = new GD::Simple($cmax, $yd);
$img->fgcolor("gray");
$img->moveTo($xmin, $yd/2);
$img->lineTo($xmax, $yd/2);

foreach my $gene (@genes) {
	if (exists $high{$gene}) {
		$img->fgcolor("green");
		#print STDERR "OK\n";
	} else {
		$img->fgcolor("black");
	}
	$x0 = $start{$gene} * $r;
	$cc = int $x0/$cmax + 1;
	$cy = $cc * 100;
	#print STDERR "$cc\n";
	#$x1 = $end{$gene} * $r;
	$x0 = $start{$gene} * $rr/$cc;
	$x1 = $end{$gene} * $rr/$cc;
	
	if ($strand{$gene} eq "+") {
		$img->bgcolor("steelblue");
		#$x0 = $start{$gene} * $r;
		#$x1 = $end{$gene} * $r;
		#print STDERR "$x0\t$x1\n";
		$img->rectangle($x0, $cy-15, $x1, $cy-5);
	} else {
		$img->bgcolor("orange");
		#$x0 = $start{$gene} * $r;
		#$x1 = $end{$gene} * $r;
		#print STDERR "$x0\t$x1\n";
		$img->rectangle($x0, $cy+5, $x1, $cy+15);
	}
	#$n++;
	#last if $n > 10;
}

print $img->png;

sub parse {
	my $line = shift;
	$pos = $line;
	$comp = 0;
	#print "DEBUG: $pos\n";
	if ($pos =~ /complement\((.+)\)/) {
		$pos = $1;
		$comp = 1;
	}
	@pos = split '\.\.', $pos;
	if ($comp) {
		push @pos, "-";
	} else {
		push @pos, "+";
	}
	#print "DEBUG: @pos\n";
	return @pos;
}
