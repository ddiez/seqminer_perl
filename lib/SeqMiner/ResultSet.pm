package SeqMiner::ResultSet;
##### SUMMARY
# this class stores several results from different hmmer/genewise searches.
# the results may come from different programs or runs.
use strict;
use warnings;

use SeqMiner::ResultSet::Result;
use Bio::SearchIO;

sub new {
	my $class = shift;
	
	my $self = {};
	$self->{id} = undef;
	$self->{nres} = 0;
	$self->{result_list} = [];
	
	bless $self, $class;
    $self->_initialize(@_) if @_;
    return $self;
}

sub _initialize {
	my $self = shift;
	$self->add(@_);
}

sub add {
	my $self = shift;
	my $param = shift;
	
	if (exists $param->{file}) {
		my $method = _detect_method_type($param->{file});
		$param->{method} = $method;
		if ($method =~ /hmmsearch|hmmpfam/) {
			$self->_parse_hmmer_file($param);
		} elsif ($method eq "genewise") {
			$self->_parse_genewise_file($param);
		} elsif ($method eq "psitblastn") {
			$self->_parse_psitblastn_file($param);
		} else {
			warn "[SearchResult:_initialize] unknown method: $method\n";
		}
	} else {
		# do something else.
	}
	
}

sub length {
	return shift->{nres};
}

sub id {
	my $self = shift;
	$self->{id} = shift if @_;
	return $self->{id};
}

sub result_ids {
	my $self = shift;
	my @res_ids;
	foreach my $res ($self->result_list) {
		push @res_ids, $res->id;
	}
	return @res_ids;
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

# alias for get_result.
sub get_result_by_pos {
	my $self = shift;
	my $n = shift;
	return $self->get_result($n);
}

sub get_result_by_id {
	my $self = shift;
	my $id = shift;
	foreach my $res ($self->result_list) {
		if ($res->id eq $id) {
			return $res;
		}
	}
	return undef;
}

sub _parse_psitblastn_file {
	my $self = shift;
	my $param = shift;
	
	my $in = new Bio::SearchIO(-format => "blast", -file => $param->{file});
	while (my $res = $in->next_result) {
		my $res_ = new SeqMiner::ResultSet::Result;
		$self->add_result($res_);
		
		$res_->id($param->{id});
		$res_->model("foo");
		$res_->method($param->{method});
		$res_->cutoff($param->{cutoff}) if defined $param->{cutoff};
		
		while (my $hit = $res->next_hit) {
			if ($hit->significance <= $res_->cutoff) {
				my $hit_ = new SeqMiner::ResultSet::Hit;
				$res_->add_hit($hit_);
				$hit_->id($hit->name);
				$hit_->score($hit->score);
				$hit_->significance($hit->significance);
				# useful for merging.
				$hit_->model($res_->model);
				$hit_->method($res_->method);
				$hit_->cutoff($res_->cutoff);
				while (my $hsp = $hit->next_hsp) {
					my $hsp_ = new SeqMiner::ResultSet::Hsp;
					$hit_->add_hsp($hsp_);
					#my $what = 'query';
					#$what = 'hit' if $param->{method} eq "hmmsearch";
					my $what = 'hit';
					$hsp_->start($hsp->start($what));
					$hsp_->end($hsp->end($what));
					#!!! TODO: check this !!!
					$hit_->start($hsp->start($what));
					$hit_->end($hsp->end($what));
				}
			}
		}
		
		#my $n = $res->num_iterations;
		#
		#if (! defined $r) {
		#	$r = $n;
		#} else {
		#	if ($r > $n) {
		#		die "ERROR: (-r $r) not so many iterations, just $n!\n";
		#	}
		#}
		#my $iter = $res->iteration($r);
		#
		#print STDERR "database: ", $res->database_name, "\n" if $O{v};
		#print STDERR "iterations: $n\n" if $O{v};
		#print STDERR "iteration: $r\n" if $O{v};
		#
		#	
		#while (my $hit = $iter->next_hit) {
		#	my $hits = $hit->significance;
		#	$hits =~ s/,$//; # FIX blast parse error in Bioperl.
		#	if (!$ecut and $scut) {
		#		print $hit->name, "\t", $hit->raw_score, "\t", $hits, "\n" if $hit->raw_score >= $scut;
		#	} elsif (!$scut and $ecut) {
		#		print $hit->name, "\t", $hit->raw_score, "\t", $hits, "\n" if $hits <= $ecut;
		#	} elsif ($ecut and $scut) {
		#		print $hit->name, "\t", $hit->raw_score, "\t", $hits, "\n" if $hit->raw_score >= $scut and $hits <= $ecut;
		#	} else {
		#		print $hit->name, "\t", $hit->raw_score, "\t", $hits, "\n";
		#	}
		#}
	}
}

sub _parse_hmmer_file {
	my $self = shift;
	my $param = shift;
	
	print STDERR $param->{file}, "\n";
	print STDERR $param->{method}, "\n";

	
	my $in = new Bio::SearchIO(-file => $param->{file}, -format => 'hmmer');
	while (my $res = $in->next_result) {
		my $res_ = new SeqMiner::ResultSet::Result;
		$res_->model_type($param->{model_type});
		$self->add_result($res_);
		
		if ($param->{method} eq "hmmsearch") {
			$res_->id($param->{id});
		} else {
			$res_->id($res->query_name);
		}
		my $model = $res->hmm_name;
		$model =~ s/(.+)\.hmm.+/$1/;
		$res_->model($model);
		$res_->method($param->{method});
		$res_->cutoff($param->{cutoff}) if defined $param->{cutoff};
		while (my $hit = $res->next_hit) {
			if ($hit->significance <= $res_->cutoff) {
				my $hit_ = new SeqMiner::ResultSet::Hit;
				$res_->add_hit($hit_);
				my $id = $hit->name;
				if ($param->{condense}) {
					$id =~ s/_..$//;
				}
				$hit_->id($id);
				$hit_->score($hit->score);
				$hit_->significance($hit->significance);
				# useful for merging.
				$hit_->model($res_->model);
				$hit_->method($res_->method);
				$hit_->cutoff($res_->cutoff);
				while (my $hsp = $hit->next_hsp) {
					my $hsp_ = new SeqMiner::ResultSet::Hsp;
					$hit_->add_hsp($hsp_);
					my $what = 'query';
					$what = 'hit' if $param->{method} eq "hmmsearch";
					$hsp_->start($hsp->start($what));
					$hsp_->end($hsp->end($what));
					#!!! TODO: check this !!!
					$hit_->start($hsp->start($what));
					$hit_->end($hsp->end($what));
				}
			}
		}
	}
}

sub _parse_genewise_file {
	my $self = shift;
	my $param = shift;
	
	# there is only one result in genewise searches.
	my $res_ = new SeqMiner::ResultSet::Result;
	$res_->id($param->{id});
	$res_->method("genewise");
	$res_->cutoff($param->{cutoff}) if defined $param->{cutoff};	
	$self->add_result($res_);
	#print STDERR "* reading result\n";
	open IN, $param->{file} or die "[SearchResult:_parse_genewise_file]: cannot open file $param->{file}: $!\n";
	while (<IN>) {
		$res_->model(_get_model($_)) if /^Protein info from/;
		next unless /^#High Score list/;
		while (<IN>) {
			last if /^#Histogram/;
			next unless /^Protein /;
			chomp;
			my ($search1, $hmm, $search2, $strand, $id, $score, $evalue) = split /\s+/, $_;
			#print STDERR "* reading hit $id\n";
			if ($evalue <= $res_->cutoff) {
				my $hit_ = new SeqMiner::ResultSet::Hit;
				$res_->add_hit($hit_);
				$hit_->id($id);
				$hit_->score($score);
				$hit_->significance($evalue);
				# useful for merging.
				$hit_->model($res_->model);
				$hit_->method($res_->method);
				$hit_->cutoff($res_->cutoff);
			}
		}
		while (<IN>) {
			next unless /^>Results/;
			my @line = split;
			my $model = $line[2];
			my $id = $line[4];
			#print STDERR "* result: $id\n";
			while (<IN>) {
				last if /^\/\//;
				next unless /Alignment (.+) Score (.+) \(Bits\)/;
				my $seq = ();
				my $pos_0 = undef;
				my $block = 0;
				#print STDERR "* alignment: $1\n";
				#print STDERR "* score: $2\n";
				my $curpos = tell IN;
				while (<IN>) {
					if (/Alignment/) {
						seek IN, $curpos, 0;
						last;
					}
					next unless /^$id/;
					$block++;
					my ($id_, $pos_, @seq_) = split;
					$pos_0 = $pos_ if !defined $pos_0;
					$seq .= join "", @seq_;
				}
				#last;
				# ISSUES:
				# give protein coordinates or gene coordinates?
				# what to do with negative values?
				my $pos_1 = $pos_0 + 3 * (CORE::length $seq);
				my $prot_0 = ($pos_0 - 1)/3;
				my $prot_1 = ($pos_1 - 1)/3;
				#print STDERR "* id: $id\n";
				#print STDERR "* blocks: $block\n";
				#print STDERR "* pos_0: $pos_0\n";
				#print STDERR "* seq: ", CORE::length $seq, "\n";
				#print STDERR "* pos_1: ", $pos_1, "\n";
				#print STDERR "* seq: #", $seq, "#\n";
				#print STDERR "* prot_0: ", ($pos_0-1)/3, "\n";
				#print STDERR "* prot_1: ", ($pos_1-1)/3, "\n";
				#print STDERR "--\n";
				my $hsp_ = new SeqMiner::ResultSet::Hsp;
				my $hit_ = $res_->get_hit_by_id($id);
				if (defined $hit_) {
					$hit_->add_hsp($hsp_);
					$hsp_->start($prot_0);
					$hsp_->end($prot_1);
					#!!! TODO: check this !!!
					$hit_->start($pos_0);
					$hit_->end($pos_1);
				}
			}
			#print STDERR "pos_1: ", $pos_0 + scalar $seq;
		}
	}
	close IN;
}

sub _get_model {
	my @line = split '\s', shift;
	my $model = pop @line;
	$model =~ s/(.+)\.hmm/$1/;
	return $1;
}

sub _detect_method_type {
	my $file = shift;
	open IN, $file or die "[SearchResult:_detect_method_type]: cannot open file $file: $!\n";
	my $method = <IN>;
	close IN;
	if ($method =~ /(hmmsearch|hmmpfam)/) {
		return $1;
	} elsif ($method =~ /Wise2/) {
		return "genewise";
	} elsif ($method =~ /PSITBLASTN/) {
		return "psitblastn";
	} else {
		print STDERR "[SearchResult:_detect_method_type]: non-supported method type: $method\n";
	}
}

# this is a special function that takes two ResultSet objects (output from
# hmmpfam) and prints a nice formated file.
sub export_pfam {
	my $param = shift;
	
	open OUT, ">", $param->{file} or
	die "[SearchPfam:export_pfam] cannot open file", $param->{file}, "for writing: $!\n";
		
	my $ls = $param->{ls};
	my $fs = $param->{fs};
	die "undefined result object!\n" if (!defined $ls or !defined $fs);
	
	print OUT
		"SEQUENCE", "\t",
		"ls_domainnum", "\t",
		"ls_domains", "\t",
		"ls_architecture", "\t",
		"fs_domainnum", "\t",
		"fs_domains", "\t",
		"fs_architecture", "\n";
	foreach my $res_ls ($ls->result_list) {
		my $id = $res_ls->id;
		my $res_fs = $fs->get_result_by_id($id);
		die "id not found in fs: $id\n" if !defined $res_fs;
		
		print OUT
			$id, "\t",
			$res_ls->length, "\t",
			$res_ls->domains_location_str, "\t",
			$res_ls->architecture, "\t",
			$res_fs->length, "\t",
			$res_fs->domains_location_str, "\t",
			$res_fs->architecture, "\n";
	}
	close OUT;
}

sub export_pfam_simple {
	my $param = shift;
	
	open OUT, ">", $param->{file} or
	die "[SearchPfam:export_pfam] cannot open file", $param->{file}, "for writing: $!\n";
		
	my $result = $param->{result};
	die "undefined result object!\n" if !defined $result;
	
	print OUT
		"SEQUENCE", "\t",
		"domainnum", "\t",
		"domains", "\t",
		"architecture", "\t",
		"domain_count", "\n";
	foreach my $res ($result->result_list) {
		my $id = $res->id;
		print STDERR "$id\n";
		
		print OUT
			$id, "\t",
			$res->length, "\t",
			$res->domains_location_str, "\t",
			$res->architecture, "\t",
			$res->num_dif_domains, "\n";
	}
	close OUT;
}

1;