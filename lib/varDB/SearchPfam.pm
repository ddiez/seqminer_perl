package varDB::SearchPfam;

use strict;
use warnings;

use Bio::SearchIO;

sub new {
	my $class = shift;
	
	my $self = {};
	bless $self, $class;
    $self->_initialize(@_);
    return $self;
}

sub _initialize {
	my $self = shift;
	my $param = shift;

	my $in = new Bio::SearchIO(-file => $param->{file}, -format => 'hmmer');

	$self->{nids} = 0;
	while (my $res = $in->next_result) {
		#print STDERR "query_name: ", $res->query_name, "\n";
		$self->{$res->query_name}->{nhits} = 0;
		while (my $hit = $res->next_hit) {
			if ($hit->significance <= 0.01) {
				my $hsp = $hit->next_hsp;
				#print STDERR "id: ", $res->query_name, "\tdomain: ", $hit->name, "\tstart: ", $hit->start, "#", $hsp->start, "\tend: ", $hit->end, "#", $hsp->end, "\n";
				push @{$self->{$res->query_name}->{$hit->name}->{score}}, $hit->score ;
				push @{$self->{$res->query_name}->{$hit->name}->{evalue}}, $hit->significance ;
				push @{$self->{$res->query_name}->{$hit->name}->{start}}, $hsp->start;
				push @{$self->{$res->query_name}->{$hit->name}->{end}}, $hsp->end;
				push @{$self->{$res->query_name}->{hit_list}}, $hit->name ;
				$self->{$res->query_name}->{nhits}++;
			}
		}
		push @{$self->{id_list}}, $res->query_name ;
		$self->{nids}++;
	}
}

sub length {
	return shift->{nids};
}

sub hits {
	my $self = shift;
	my $id = shift;
	return $self->{$id}->{nhits};
}

sub id_list {
	my $self = shift;
	return @{ $self->{id_list} };
}

sub hit_list {
	my $self = shift;
	my $id = shift;
	return @{ $self->{$id}->{hit_list} } if $self->{$id}->{nhits} > 0;
}

sub score {
	my $self = shift;
	my $id = shift;
	my $hit = shift;
	return $self->{$id}->{$hit}->{score};
}

sub evalue {
	my $self = shift;
	my $id = shift;
	my $hit = shift;
	return $self->{$id}->{$hit}->{evalue};
}

sub start {
	my $self = shift;
	my $id = shift;
	my $hit = shift;
	my $n = shift;
	return $self->{$id}->{$hit}->{start}->[$n];
}

sub end {
	my $self = shift;
	my $id = shift;
	my $hit = shift;
	my $n = shift;
	return $self->{$id}->{$hit}->{end}->[$n];
}

sub export_pfam {
	my $self = shift;
	my $param = shift;
	
	open OUT, ">", $param->{file} or
	die "[SearchPfam:export_pfam] cannot open file", $param->{file}, "for writing: $!\n";
	
	print OUT
		"SEQUENCE", "\t",
		"domainnum", "\t",
		"domains", "\n";
	foreach my $id ($self->id_list) {
		my @domains = ();
		foreach my $hit ($self->hit_list($id)) {
			push @domains, "$hit:".$self->start($id, $hit, 0)."..".$self->end($id, $hit, 0);
		}
		my $domains = join ";", @domains;
		print OUT
			$id, "\t",
			$self->hits($id), "\t",
			$domains, "\n";
	}
	close OUT;
}

1;