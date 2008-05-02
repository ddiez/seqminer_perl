package varDB::ResultSet;

use strict;
use warnings;

use varDB::ResultSet::Result;
use Bio::SearchIO;

sub new {
	my $class = shift;
	
	my $self = {};
	$self->{name} = undef;
	$self->{nres} = 0;
	$self->{result_list} = [];
	
	bless $self, $class;
    $self->_initialize(@_) if @_;
    return $self;
}

sub _initialize {
	my $self = shift;
	my $param = shift;
	
	$self->{file} = $param->{file};
	if (defined $param->{method}) {
		$self->{method} = $param->{method};
	} else {
		$self->{method} = _detect_method_type($self->{file});
	}

	if ($self->{method} eq "hmmer") {
		$self->_parse_hmmer_file($self->{file});
	} elsif ($self->{method} eq "genewise") {
		$self-> _parse_genewise_file($self->{file});
	} else {
		warn "[SearchResult:_initialize] unknown method: $self->{method}\n";
	}
}

sub length {
	return shift->{nres};
}

sub name {
	my $self = shift;
	$self->{name} = shift if @_;
	return $self->{name};
}

sub result_list {
	return @{ shift->{result_list} };
}

sub add_result {
	my $self = shift;
	my $res = shift;
	push @{$self->{result_list}}, $res;
	$self->{nres}++;
}

sub get_result {
	my $self = shift;
	my $n = shift;
	return undef if $n > $self->length;
	return $self->{result_list}->[$n];
}

sub get_result_by_id {
	my $self = shift;
	my $id = shift;
	foreach my $res ($self->result_list) {
		if ($res->name eq $id) {
			return $res;
		}
	}
	return undef;
}

sub export_pfam {
	my $self = shift;
	my $param = shift;
	
	
	open OUT, ">", $param->{file} or
	die "[SearchPfam:export_pfam] cannot open file", $param->{file}, "for writing: $!\n";
	
	print OUT
		"SEQUENCE", "\t",
		"ls_domainnum", "\t",
		"ls_domains", "\t",
		"ls_architecture", "\t",
		"fs_domainnum", "\t",
		"fs_domains", "\t",
		"fs_architecture", "\n";
	foreach my $res ($self->result_list) {
	#foreach my $n (0 .. $self->length) {
		#my $res = $self->get_result($n);
		my $res2 = $param->{fs}->get_result_by_id($res->name);
		print OUT
			$res->name, "\t",
			$res->length, "\t",
			$res->domains_location_str, "\t",
			$res->architecture, "\t",
			$res2->length, "\t",
			$res2->domains_location_str, "\t",
			$res2->architecture, "\n";
	}
	close OUT;
}

sub _parse_hmmer_file {
	my $self = shift;
	my $file = shift;
	my $cutoff = shift;
	my $model;
	
	$cutoff = 0.01 if !defined $cutoff; # set default cutoff.
	
	my $in = new Bio::SearchIO(-file => $file, -format => 'hmmer');
	while (my $res = $in->next_result) {
		my $res_ = new varDB::ResultSet::Result;
		$self->add_result($res_);
		$res_->name($res->query_name);
		while (my $hit = $res->next_hit) {
			if ($hit->significance <= $cutoff) {
				my $hit_ = new varDB::ResultSet::Hit;
				$res_->add_hit($hit_);
				$hit_->name($hit->name);
				$hit_->score($hit->score);
				$hit_->significance($hit->significance);
				while (my $hsp = $hit->next_hsp) {
					my $hsp_ = new varDB::ResultSet::Hsp;
					$hit_->add_hsp($hsp_);
					$hsp_->start($hsp->start);
					$hsp_->end($hsp->end);
				}
			}
		}
	}
	
	#open IN, $file or die "[SearchResult:_parse_hmmer_file]: cannot open file $file: $!\n";
	#while (<IN>) {
	#	if (/HMM file/) {
	#		my @line1 = split;
	#		$model = $line1[$#line1-1];
	#		$model =~ s/(.+)\.hmm/$1/;
	#	}
	#	next unless /^Scores for complete sequences/;
	#	while (<IN>) {
	#		last if /^[\n]$/;
	#		next if /^Sequence\s+Description/o || /^\-\-\-/o;
	#		chomp;
	#		my @line = split;
	#		my ($id, $n, $evalue, $score) = (shift @line, pop @line, pop @line, pop @line);
	#		if ($evalue <= $cutoff) {
	#			$self->{id}->{$id}->{score} = $score;
	#			$self->{id}->{$id}->{evalue} = $evalue;
	#			$self->{id}->{$id}->{quality} = "";
	#			$self->{id}->{$id}->{eexons} = 0;
	#			$self->{id}->{$id}->{pexons} = 0;
	#			$self->{id}->{$id}->{strand} = "";
	#			$self->{id}->{$id}->{method} = "hmmer";
	#			$self->{id}->{$id}->{model} = $model;
	#			push @{$self->{id_list}}, $id;
	#			$self->{nids}++;
	#		}
	#	}
	#}
	#close IN;
}

sub _parse_genewise_file {
	my $self = shift;
	my $file = shift;
	my $cutoff = shift;
	my $model;
	
	$cutoff = 0.01 if !defined $cutoff; # set default cutoff.
	
	open IN, $file or die "[SearchResult:_parse_genewise_file]: cannot open file $file: $!\n";
	while (<IN>) {
		if (/Protein info from/) {
			my @line = split;
			$model = pop @line;
			$model =~ s/(.+)\.hmm/$1/;
		}
		next unless /^#High Score list/;
		my $skip = <IN>;
		$skip = <IN>;
		while (<IN>) {
			last if /^[\n]$/;
			chomp;
			my ($search1, $hmm, $search2, $strand, $id, $score, $evalue) = split /\s+/, $_;
			if ($evalue <= $cutoff) {
				$self->{id}->{$id}->{score} = $score;
				$self->{id}->{$id}->{evalue} = $evalue;
				$self->{id}->{$id}->{quality} = "";
				$self->{id}->{$id}->{eexons} = 0;
				$self->{id}->{$id}->{pexons} = 0;
				$self->{id}->{$id}->{strand} = $strand =~ /\[(.)\]/ ? $1 : "";
				$self->{id}->{$id}->{method} = "genewise";
				$self->{id}->{$id}->{model} = $model;
				push @{$self->{id_list}}, $id;
				$self->{nids}++;
			}
		}
	}
	close IN;
}

sub _detect_method_type {
	my $file = shift;
	open IN, $file or die "[SearchResult:_detect_method_type]: cannot open file $file: $!\n";
	my $method = <IN>;
	close IN;
	if ($method =~ /hmmsearch|hmmpfam/) {
		return "hmmer";
	} elsif ($method =~ /Wise2/) {
		return "genewise";
	} else {
		print STDERR "[SearchResult:_detect_method_type]: non-supported method type: $method\n";
	}
}

1;