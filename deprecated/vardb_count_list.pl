#!/usr/bin/env perl

$file = shift;
$tag = shift;

if (! defined $tag) {
	$tag = $file;
	$tag =~ s/\.list//;
}

open IN, $file;
while (<IN>) {
	$n++;
}
print "$n\t$tag\n";
