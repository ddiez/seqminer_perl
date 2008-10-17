package varDB::NCBI;

use strict;
use warnings;

use Bio::DB::EUtilities;
use varDB::Config;
use varDB::NCBI::Filter;
use varDB::NCBI::Paper;
use varDB::NCBI::Author;
use varDB::NCBI::Keyword;

sub new {
	my $class = shift;
	
	my $self = {};
	
	bless $self, $class;
    $self->_initialize(@_);
    return $self;
}

sub _initialize {
	my $self = shift;
	
	open IN, "$VARDB_TAXON_FILE" or die "$!";
	while (<IN>) {
		next if /^#/;
		chomp;
		my ($taxon_name, $taxid) = split '\t', $_;
		$self->{taxon}->{$taxid} = $taxon_name;
		push @{$self->{taxon_list}}, $taxid;
		$self->{length}++;
	}
	close IN;
	
	$self->{filter} = new varDB::NCBI::Filter;
	$self->{paper} = new varDB::NCBI::Paper;
	$self->{author} = new varDB::NCBI::Author;
	$self->{keyword} = new varDB::NCBI::Keyword;
}

sub length {
	return shift->{length};
}

sub taxon_by_pos {
	return shift->{taxon_list}->[shift];
}

sub taxon_by_id {
	return shift->{taxon}->{(shift)};
}

sub taxon_list {
	return @{shift->{taxon_list}};
}

sub filter {
	my $self = shift;
	$self->{filter}->get(shift);
}


sub search {
	my $self = shift;
	my $base = $VARDB_HOME."/db/genbank/test2";
	
	foreach my $taxid ($self->taxon_list) {
		my $taxon = $self->taxon_by_id($taxid);
		print STDERR "[DEBUG] $taxon\n";
		print STDERR "[DEBUG] $taxid\n";
		
		my $dir = "$base/$taxon";
		# TODO: change to correct directory.
		if(! -d $dir) {
			mkdir $dir;
		}
		chdir $dir;
		
		# data download.
		print STDERR "taxon: $taxon\n";
		print STDERR "db: nuccore\n";
		&_seq_download($taxid, 'nuccore', 'core.gb');
		#print STDERR "db: nucest\n";
		#&_seq_download($ts{$t}, 'nucest', 'est.gb');
		
		# data filtering.
		mkdir "$dir/project/" if ! -d "$dir/project";
		mkdir "$dir/isolate/" if ! -d "$dir/isolate";
		$self->_seq_filter($dir, "core.gb");
		#&_seq_filter($dir, "est.gb");
		
		# TODO: project files follow diferent pipeline.
		
		# format data:
		&_format("$dir/isolate", "core.gb");
		#&_format("$dir/isolate", "est.gb");
		
		# run searches.
		&_run_search("$dir/isolate", "core.fa");
		#&_run_search("$dir/isolate", "est.fa");
		
		# select sequences from original dataset.
		&_select("$dir/isolate", "core.sel.list");
		
		# paper distribution.
		&_paper_dist("$dir/isolate", "core.sel.gb", $taxon, "vsp");
	}
}

sub _fix_taxid {
	return "txid".(shift)."[Organism:exp]";
}

sub _seq_download {
	my $id = _fix_taxid(shift);
	my $db = shift;
	my $file = shift;
	
	
	unlink $file;
	
	print STDERR "downloading: $id\n";
	print STDERR "|";
	my $factory = new Bio::DB::EUtilities (
		-eutil => 'esearch',
		-term  => $id,
		-db => $db,
		-usehistory => 'y'
	);
	
	my $count = $factory->get_count;
	if ($count > 0) {
		my $hist = $factory->next_History || die 'No history data returned';
		$factory->set_parameters(
			-eutil => 'efetch',
			-rettype => 'genbank',
			-history => $hist
		);
		
		my ($retmax, $retstart) = (500, 0);
		my $retry = 0;
		RETRIEVE_SEQS:
		while ($retstart < $count) {
			$factory->set_parameters(-retmax => $retmax,
									-retstart => $retstart);
			eval{
				print STDERR "=";
				$factory->get_Response(-file => ">>$file");
			};
			if ($@) {
				die "Server error: $@.  Try again later" if $retry == 5;
				print STDERR "Server error, redo #$retry\n";
				$retry++ && redo RETRIEVE_SEQS;
			}
			$retstart += $retmax;
		}

	} else {
		# do something?
	}
	print STDERR "|\n";
}

sub _seq_filter {
	my $self = shift;
	my $dir = shift;
	my $file = shift;
	
	my $filter = 0;
	
	#unlink "$dir/project/$file";
	#unlink "$dir/isolate/$file";
	
	open OUT1, ">$dir/project/$file" or die "$!";
	open OUT2, ">$dir/isolate/$file" or die "$!";
	open IN, "$dir/$file" or die "$!";
	while (<IN>) {
		if (/^LOCUS/) {
			$a .= $_;
			while (<IN>) {
				$a .= $_;
				$filter = 1 if /^PROJECT/;
				if (/\s+?TITLE\s+(.+)/) {
					$filter = 1 if _check_title($1, $self->{filter}->{'TITLE'});
				}
				if (/\s+?PUBMED\s+(.+)/) {
					$filter = 1 if _check_pubmed($1, $self->{filter}->{'PUBMED'});
				}
				if (/^\/\//) {
					# check project.
					if ($filter == 1) {
						# print.
						print OUT1 $a;
					} else {
						# print.
						print OUT2 $a;
					}
					# reset.
					$filter = 0;
					$a = "";
					last;
				}
			}
		}
	}
	close IN;
	close OUT1;
	close OUT2;
}

sub _check_title {
	my $line = shift;
	my @title = @{ (shift) };
	return 0 if $line eq "Direct Submission";
	#print STDERR "begin check\n";
	#print STDERR "checking: #$line#\n";
	#print STDERR "and: @title\n";
	foreach my $title (@title) {
		return 1 if $title eq $line;
	}
	return 0;
}

sub _check_pubmed {
	my $line = shift;
	my @pubmed = @{ (shift) };
	foreach my $pubmed (@pubmed) {
		my @refs = split ";", $pubmed;
		foreach my $ref (@refs) {
			return 1 if $ref eq $line;
		}
	}
	return 0;
}

sub _format {
	my $dir = shift;
	my $infile = shift;
	
	print STDERR "format: $infile\n";
	chdir $dir;
	
	my $basename = $infile;
	$basename =~ s/.gb//;	
	my $outfile = $basename.".fa";
	
	use Bio::SeqIO;
	
	my $in = new Bio::SeqIO(-file => "$infile", -format => 'genbank');
	my $out = new Bio::SeqIO(-file => ">$outfile", -format => 'fasta');

	open OUT, ">$basename.skip" or die "$!";
	while (my $seq = $in->next_seq) {
		if (defined $seq->seq) {
			$out->write_seq($seq);
		} else {
			print OUT $seq->display_id, "\n";
		}
	}
	close OUT;
	
	system "formatdb -i $outfile -n $basename -p F"
}

sub _run_search {
	my $dir = shift;
	my $file = shift;
	
	print STDERR "search: $file\n";
	chdir $dir;
	
	my $base = $file;
	$base =~ s/.fa//;
	
	my $evalue = 0.01;
	
	# where PSSM and seed are located.
	#my $pssm_file = "$PSIBLASTDB/pssm/var.chk";
	#my $seed_file = "$PSIBLASTDB/seed/var.seed";
	
	#my $pssm_file = "$PSIBLASTDB/pssm/msp2.chk";
	#my $seed_file = "$PSIBLASTDB/seed/msp2.seed";
	
	#my $pssm_file = "$PSIBLASTDB/pssm/vir.chk";
	#my $seed_file = "$PSIBLASTDB/seed/vir.seed";
	
	my $pssm_file = "$PSIBLASTDB/pssm/vsp.chk";
	my $seed_file = "$PSIBLASTDB/seed/vsp.seed";
	
	# run PSI-Blast.
	system "blastall -p psitblastn -d $base -i $seed_file -R $pssm_file -b 100000 > $base.psitblastn";
	system "blast_parse.pl -i $base.psitblastn -e $evalue > $base.sel.list";
}

sub _select {
	my $dir = shift;
	my $file = shift;
	
	my $base = $file;
	$base =~ s/.sel.list//;
	
	use Bio::SeqIO;

	my %id = ();
	
	open IN, "$dir/$file";
	while (<IN>) {
		chomp;
		my ($id, $score, $evalue) = split '\t', $_;
		$id{$id}->{score} = $score;
		$id{$id}->{evalue} = $evalue;
	}
	
	my $in = new Bio::SeqIO( -file => "$dir/$base.gb", -format => 'genbank');
	my $out = new Bio::SeqIO( -file => ">$dir/$base.sel.gb", -format => 'genbank');
	while (my $seq = $in->next_seq) {
		$out->write_seq($seq) if exists $id{$seq->display_id};
	}
}

sub _paper_dist {
	my $dir = shift;
	my $file = shift;
	my $org = shift;
	my $family = shift;
	
	my $base = $file;
	$base =~ s/.sel.gb//;
	
	use Bio::SeqIO;
	
	my %j;

	my $in = new Bio::SeqIO( -file => "$dir/$file", -format => 'genbank');
	while (my $seq = $in->next_seq) {
		my $ac = $seq->annotation;
		my $pubmed = ($ac->get_Annotations("reference"))[0]->pubmed;
		if (defined $pubmed) {
			$j{$pubmed}++;
		} else {
			$j{'unpublished'}++;
		}
	}
	
	open OUT, ">$dir/$base.sel.papers.txt";
	print OUT "journals: ", scalar keys %j, "\n";
	
	for my $ref (keys %j) {
		print OUT "$ref\t$j{$ref}\n";
	}
	close OUT;
	
	use varDB::R;
	my $r = new varDB::R;
	my $title = "$org - $family";
	$r->barplot($dir, "$base.sel.papers.txt", $title);
}

1;
