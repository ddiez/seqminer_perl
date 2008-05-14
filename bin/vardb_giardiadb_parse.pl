#!/usr/bin/env perl

use strict;
use warnings;
use Getopt::Long;

my %O = ();
GetOptions(\%O, 't:s', 'i:s', 's:s');
if ($O{t} eq "gff") {
	use varDB::GFF;
	use varDB::Genome;
	my $gff = new varDB::GFF;
	my $genome = new varDB::Genome;
	my $file = $O{i};
	
	open IN, $file or die "ERROR: cannot open file $file: $!\n";
	while (<IN>) {
		last if /^##FASTA/; # skip sequences.
		next if /^##/; # skip comments.
		chomp;
		my ($id, $source, $type, $start, $end, $foo, $strand, $foo2, $info) = split '\t', $_;
		my $chr = $1 if $id =~ /apidb\|(.+)/;
		if ($type eq "gene") {
			$info = $gff->parse($info, "gene");
			my $gene = new varDB::Genome::Gene($info);
			$gene->chromosome($chr);
			$gene->strand($strand);
			$gene->start($start);
			$gene->end($end);
			$gene->source("giardiadb");
			$genome->add_gene($gene);
		#	$gene->set_description("") if !defined $gene->get_description;
		} elsif ($type eq "exon") {
			$info = $gff->parse($info, "exon");
			my $exon = new varDB::Genome::Exon($info);
			$exon->strand($strand);
			$exon->start($start);
			$exon->end($end);
			$genome->add_exon($exon);
		} # skip other information.
	}
	close IN;
	
	$genome->print_gff;
} elsif ($O{t} eq "fasta") {
	use Bio::SeqIO;
	my $in = new Bio::SeqIO(-file => $O{i});
	my $out = new Bio::SeqIO(-fh => \*STDOUT, -format => 'fasta');
	while (my $seq = $in->next_seq) {
		if (exists $O{s} and $O{s} eq "genome") {
			my $id = $1 if $seq->display_id =~ /.+\|(.+)/;
			my ($foo, $org, $version, $len) = split /\s*\|\s/, $seq->description;
			$org =~ s/organism=//g;
			$org =~ s/\_/ /g;
			$seq->display_id($id);
			$seq->description("organism=$org;source=giardiadb");
		} else {
			my $id = $1 if $seq->display_id =~ /.+\|(.+)/;
			my ($foo, $org, $desc, $loc, $len) = split /\s*\|\s/, $seq->description;
			$org =~ s/organism=//g;
			$org =~ s/\_/ /g;
			my $chr = $loc;
			$chr =~ s/location=//;
			$chr =~ s/(.+):.+/$1/;
			$desc =~ s/product=//;
			$seq->display_id($id);
			$seq->description("description=$desc;organism=$org;source=giardiadb;chromosome=$chr");
		}
		$out->write_seq($seq);
	}
}