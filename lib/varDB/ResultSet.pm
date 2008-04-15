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
	$self->{res_list} = [];
	
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
		die "[SearchResult:_initialize] unknown method: $self->{method}\n";
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

sub res_list {
	return @{ shift->{res_list} };
}

{ # other option would be to store n in the class itself.
	my $n = 0;
	sub next_result {
		my $self = shift;
		return $self->{res_list}->[$n++];
	}
	
	sub rewind {
		my $self = shift;
		$n = 0;
	}
}

sub add_result {
	my $self = shift;
	my $res = shift;
	push @{$self->{res_list}}, $res;
	$self->{nres}++;
}

sub get_result {
	my $self = shift;
	my $n = shift;
	return undef if $n > $self->length;
	return $self->{res_list}->[$n];
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
		die "[SearchResult:_detect_method_type]: non-supported method type: $method\n";
	}
}

1;