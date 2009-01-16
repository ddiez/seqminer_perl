#!/usr/bin/env perl
#

use strict;
use ConSeq::SeqArray;
use Getopt::Long;

###############################################################################
my %O = ();
GetOptions(\%O, 'i=s', 'o=s', 'l1=i', 'l2=i', 'l3=i', 'max_gap=i', 'min_res=i', 'max_cycle=i', 'con_adj=i', 'debug=i', 'program=s');


# program.
my $program = 'clustalw';
$program = $O{program} if($O{program});

# debug.
my $debug = 0;
$debug = 1 if($O{debug});

# for consensus.
my %param = (
	l3 => 80,
	l2 => 70,
	l1 => 60,
);
$param{l3} = $O{l3} if(exists $O{l3});
$param{l2} = $O{l2} if(exists $O{l2});
$param{l1} = $O{l1} if(exists $O{l1});

my %param2 = (
	l3 => 90,
	l2 => 80,
	l1 => 70
);
$param2{l3} = $O{s3} if(exists $O{s3});
$param2{l2} = $O{s2} if(exists $O{s2});
$param2{l1} = $O{s1} if(exists $O{s1});

# for cluster.
my %cluster_param = (
	max_gap => 5,
	min_res => 5
);
$cluster_param{max_gap} = $O{max_gap} if(exists $O{max_gap});
$cluster_param{min_res} = $O{min_res} if(exists $O{min_res});

# for alignment.
my %align_param = (	
);

# number of cycles.
my $max_cycle = 10;
$max_cycle = $O{max_cycle} if(exists $O{max_cycle});
my $cycle = 1;

# residue adjustment.
my $con_adj = 10;
$con_adj = $O{con_adj} if(exists $O{con_adj});

# help message.
my $help = <<HELP;

Usage: vardb_align.pl -i <file> -o <basename> [-l1 <integer> -l2 <integer>
             -l3 <integer> -c1 <integer> -c2 <integer> -c3 <integer> 
             -max_gap <integer> -min_res <integer> -max_cycle <integer>]

  -i           input file (any format supported by Bioperl Bio::SeqIO
                  interface.
  -o           base name for output files.
  -program     alignment program to use [default: clustalw]

  -l1          cutoff for level 1 [default: $param{l1}]
  -l2          cutoff for level 2 [default: $param{l2}]
  -l3          cutoff for level 3 [default: $param{l3}]

  -max_gap     max number of gaps [default: $cluster_param{max_gap}]
  -min_res     min number of residues [default: $cluster_param{min_res}]

  -c1          final level1 consensus cutoff [default: $param2{l1}]
  -c2          final level2 consensus cutoff [default: $param2{l2}]
  -c3          final level3 consensus cutoff [default: $param2{l3}]

  -max_cycle   max number of cycles to run [default: 10]

  -con_adj     number of residues included to the left and right from the
                 automatic conserved region estimation [default: 10]

  -debug       if non-zero, debug information is thrown to stderr [default: 0]

HELP
###############################################################################

# die if no mandatory arguments are provided.
die $help if(!$O{o} or !$O{i});

###############################################################################

# initial alignment.
my $sa = new ConSeq::SeqArray({file => $O{i}});
my $aln = $sa->align({program => $program, iteration => 'alignment'});
my $cs = $aln->conseq(%param);
$cs->id("cycle-$cycle");
my $sum = $cs->summary;
my $c0 = $cs->cluster(%cluster_param);

# print alignment.
my $file = "$O{o}-$cycle.faln";
my $aln_tmp = $aln->clone;
$aln_tmp->add($cs, $c0->as_seq);
$aln_tmp->write({file => $file});

# log info.
log_head();
log_line($cycle, $cs, $c0);
#$cs->print(-fh => \*STDERR);
#$c0->print(-fh => \*STDERR);
#$c0->debug;

###############################################################################
# conserved region fine tunning.
# only one cycle right now...
$cycle++;
my @aln0 = ();
$c0->print;
$c0->debug;
my $c_ = $c0->clone;
$c_->expand(-size => 10);
$c_->print;
$c_->debug;
foreach my $n (1 .. $c_->no_cluster) {
	my $tmp = $aln->slice($c_->start($n), $c_->end($n));
	print STDERR "  - fine tunning (valid seq?): ", $tmp->is_valid, "\n";
	if($tmp->length > 1 and $tmp->is_alignable) {	
		if($c_->description($n) eq 'conserved') {
			my $tmp2 = $tmp->align({program => $program});
			push @aln0, $tmp2;
		} else {
			push @aln0, $tmp;
		}
	} else {
		push @aln0, $tmp;
	}
}

$aln = shift @aln0;
$aln->debug;
while(@aln0) {
	$aln = $aln->combine(shift @aln0);
	$aln->debug;
}
$cs = $aln->conseq(%param);
$cs->id("cycle-$cycle");
$sum->add($cs);
$c0 = $cs->cluster(%cluster_param);

# print alignment.
$file = "$O{o}-$cycle.faln";

$aln_tmp = $aln->clone;
$aln_tmp->add($cs, $c0->as_seq);
$aln_tmp->write({file => $file});

# log.
log_line($cycle, $cs, $c0);
#$cs->print(-fh => \*STDERR);
#$c0->print(-fh => \*STDERR);
#$c0->debug;


# return the min value.
#sub min {
	#my @tmp = @_;
	#my $min = $tmp[0];
	#foreach my $tmp (@tmp) {
		#$min = $tmp if($min <= $tmp);
	#}
	#return $min;
#}

## return the max value.
#sub min {
	#my @tmp = @_;
	#my $max = $tmp[0];
	#foreach my $tmp (@tmp) {
		#$max = $tmp if($max >= $tmp);
	#}
	#return $max;
#}

###############################################################################
# variable region realignment.
while($cycle++ < $max_cycle) {
	my @aln = ();
	print STDERR ">> CYCLE $cycle\n";
	foreach my $n (1 .. $c0->no_cluster) {
		print STDERR "+ cluster n: $n\n";
		my $tmp = $aln->slice($c0->start($n), $c0->end($n));
		print STDERR "  - number of sequences: ", $tmp->no_sequences, "\n";
		print STDERR "  - type: ", $c0->description($n), "\n";
		
		# check if we have at least two non-empty sequences with at least two
		# residues.
		print STDERR "  - hypervariable (valid seq?): ", $tmp->is_valid, "\n";
		if($tmp->length > 1 and $tmp->is_alignable) {
			if($c0->description($n) eq 'conserved') {
				push @aln, $tmp;
			} else {
				#my $sa2 = $tmp->toSeqArray;
				#my $tmp2 = $sa2->align({program => $program});
				my $tmp2 = $tmp->align({program => $program});
				push @aln, $tmp2;
			}
		} else {
			push @aln, $tmp;
		}
	}

	$aln = shift @aln;
	while (@aln) {
		$aln = $aln->combine(shift @aln);
	}
	$cs = $aln->conseq(%param);
	$cs->id("cycle-$cycle");
	$sum->add($cs);
	my $c1 = $cs->cluster(%cluster_param);

	# print alignment.
	$file = "$O{o}-$cycle.faln";
	
	$aln_tmp = $aln->clone;
	$aln_tmp->add($cs, $c1->as_seq);
	$aln_tmp->write({file => $file});
	#$aln->print(-file => ">".$file);
	#$cs->print(-file => ">>".$file);
	#$c1->print(-file => ">>".$file);

	# log.
	log_line($cycle, $cs, $c1);
	#$cs->print(-fh => \*STDERR);
	#$c1->print(-fh => \*STDERR);
	#$c1->debug;
	
	# exit?.
	if(!$c0->identical($c1)) {
		$c0 = $c1->clone;
	} else {
		last;
	}
}

exit;
###############################################################################
# final report.

print STDERR ">>> FINAL\n" if($debug);
#$aln->debug;
my $fcs = $aln->conseq(%param2);
$fcs->id("final");
my $fc = $fcs->cluster(%cluster_param);
$fcs->print(-file => ">>".$file);
$fc->print(-file => ">>".$file);

#$fcs->print(-fh => \*STDERR);
#$fc->print(-fh => \*STDERR);
#$fc->debug;

# print summary file.
$sum->print(-file => "$O{o}.stats.txt");


###############################################################################

# print log header.
sub log_head {
	open OUT, ">$O{o}.log" or die "ERROR: cannot create file: $!.\n";
	print OUT "# program: $program\n";
	print OUT "# l1: $param{l1}\n";
	print OUT "# l2: $param{l2}\n";
	print OUT "# l3: $param{l3}\n";
	print OUT "# s1: $param2{l1}\n";
	print OUT "# s2: $param2{l2}\n";
	print OUT "# s3: $param2{l3}\n";
	print OUT "# max_gap: $cluster_param{max_gap}\n";
	print OUT "# min_res: $cluster_param{min_res}\n";
	print OUT "# max_cycle: $max_cycle\n";
	print OUT "Cycle\tLength\tN-clusters\tScore\tScore-adj\n";
	close OUT;
}

# print log line.
sub log_line {
	my $cycle = shift;
	my $cs = shift;
	my $c = shift;

	print STDERR ">>> Cycle $cycle\n" if($debug);
	open OUT, ">>$O{o}.log" or die "ERROR: cannot create file: $!.\n";
	print OUT "$cycle\t", $cs->length, "\t", $c->no_cluster, "\t", $cs->score->score, "\t", $cs->score->score_adj, "\n";
	close OUT;
}
