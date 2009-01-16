#!/usr/bin/env perl


$file = shift;
$basename = $file;
$basename =~ s/^(.+)\.fa/$1/;

print STDERR "indexing $file ($basename)\n";

if ($file =~ /protein/) {
	system "formatdb -i $file -n $basename -p T";
	system "index_fasta.pl $file $basename.idx";
} elsif ($file =~ /gene/) {
	system "formatdb -i $file -n $basename -p F";
	system "index_fasta.pl $file $basename.idx";
}
