use Bio::SeqIO;

use strict;
use warnings;

my $in = new Bio::SeqIO(-file => shift, -format => 'EMBL');

my $n = 0;
my %count;
my %def;
my %strain;
my %taxon;
while (my $seq = $in->next_seq) {
	print STDERR $seq->display_id, "\n";
	#$n++;
	#my $taxid = $seq->species->ncbi_taxid;
	my $taxid = "2501";
	if (defined $taxid) {
		#if (! exists $count{$taxid}) {
			#print STDERR "taxon: $taxid\n";
			#print STDERR "species: ", $seq->species->binomial, "\n";
			#print STDERR "variant: ", $seq->species->variant, "\n" if defined $seq->species->variant;
			#print STDERR "\n";
		#}
		$count{$taxid}++;
		#$def{$taxid} = $seq->desc if ! exists $def{$taxid};
		#$strain{$taxid} = $seq->species->variant if ! exists $strain{$taxid};
		if (defined $seq->seq) {
			#my $base = $seq->species->ncbi_taxid.".fa";
			my $base = $taxid.".fa";
			#$base = lc $base;
			#$base =~ s/\s/\./g;
			
			# export genome.
			my $out = new Bio::SeqIO(-file => ">>genome-$base", -format => 'fasta');
			$out->write_seq($seq);
			$out->close;

			# is there any gene feature?
			my @feat = $seq->get_all_SeqFeatures;
			for my $feat (@feat) {
				if ($feat->primary_tag eq "CDS") {
					my $gene = $feat->seq;
					if ($feat->has_tag("temporary_systematic_id")) {
						$gene->display_id($feat->get_tag_values("temporary_systematic_id"));
						$gene->description($feat->get_tag_values("product")) if $feat->has_tag("product");
					} elsif ($feat->has_tag("previous_systematic_id")) {
						$gene->display_id($feat->get_tag_values("previous_systematic_id"));
						$gene->description($feat->get_tag_values("product")) if $feat->has_tag("product");
					} else {
						print STDERR "WARNING: feature CDS without systematic id: ", $feat->display_name, "\n";
						$gene->display_id("display_name");
						$gene->description($feat->get_tag_values("product")) if $feat->has_tag("product");
					}
					
					my $out = new Bio::SeqIO(-file => ">>gene-$base", -format => 'fasta');
					$out->write_seq($gene);
					$out->close;
					#}
				
					#if ($feat->primary_tag eq "CDS") {
					#my $gene = $feat->seq;
					#$gene->display_id($feat->get_tag_values("temporary_systematic_id"));
					#$gene->description($feat->get_tag_values("product"));
					
					$out = new Bio::SeqIO(-file => ">>protein-$base", -format => 'fasta');
					$out->write_seq($gene->translate);
					$out->close;
				}
			}
		} else {
			#print STDERR "WARNING: sequence ", $seq->display_id, " with no sequence data.\n";
		}
	} else {
		print STDERR "WARNING: sequence ", $seq->display_id, " with no taxon attached.\n";
	}
	#last if $n == 50;
}

for my $kk (keys %count) {
	print "# $kk\t# $strain{$kk}\t# $taxon{$kk}\t# $def{$kk}\n";
}
