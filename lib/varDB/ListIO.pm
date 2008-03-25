package varDB::ListIO;

use strict;
use warnings;

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
	
	my $file = $param->{file};
	open TMP, $file or die "ERROR [parse_list_file]: cannot open file $file: $!\n";
	
	$self->{file} = $file;
	while (<TMP>) {
		chomp;
		my ($id, $score, $evalue) = split '\t', $_;
		if (! exists $self->{gene}->{$id}) {
			$self->{gene}->{$id}->{score} = $score;
			$self->{gene}->{$id}->{evalue} = $evalue;
			$self->{gene}->{$id}->{quality} = "";
			push @{$self->{gene_list}}, $id;
			$self->{nseq}++;
		} else {
			print STDERR "WARNING [parse_list_file]: duplicated id $id\n";
		}
	}
	close TMP;
}

sub get_subset {
	my $self = shift;
	my @ids = @_;
	
	foreach my $id (@ids) {
	}
}

sub get_file {
	return shift->{file};
}

sub get_gene_list {
	return shift->{gene_list};
}

sub get_number {
	return shift->{nseq};
}

sub get_id {
	return shift->{gene_list}->[shift];
}

sub get_score {
	my $self = shift;
	my $id = shift;
	return $self->{gene}->{$id}->{score};
}

sub get_evalue {
	my $self = shift;
	my $id = shift;
	return $self->{gene}->{$id}->{evalue};
}

sub get_quality {
	my $self = shift;
	my $id = shift;
	return $self->{gene}->{$id}->{quality};
}

sub set_quality {
	my $self = shift;
	my $id = shift;
	my $quality = shift;
	$self->{gene}->{$id}->{quality} = $quality;
}

1;
