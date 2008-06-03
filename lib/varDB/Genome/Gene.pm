package varDB::Genome::Gene;

use varDB::Genome::Exon;
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
	$self->{id} = $param->{id};
	$self->{name} = $param->{name};
	$self->{description} = $param->{description};
	$self->{pseudogene} = 0;
	$self->{chromosome} = $param->{chromosome};
	$self->{start} = $param->{start};
	$self->{end} = $param->{end};
	$self->{strand} = $param->{strand};
	$self->{source} = $param->{source};
	$self->{exons} = {};
	$self->{exon_list} = [];
	$self->{seq} = $param->{seq};
	$self->{translation} = $param->{translation};
	$self->{nexons} = 0;
}

sub id {
	my $self = shift;
	$self->{id} = shift if @_;
	return $self->{id};
}

sub name {
	my $self = shift;
	$self->{name} = shift if @_;
	return $self->{name};
}

sub pseudogene {
	my $self = shift;
	# TODO: check valid values.
	$self->{pseudogene} = shift if @_;
	return $self->{pseudogene};
}

sub description {
	my $self = shift;
	$self->{description} = shift if @_;
	return $self->{description};
}

sub get_gff_desc {
	my $self = shift;
	return "description=".$self->description.";pseudogene=".$self->pseudogene.";";
}

sub chromosome {
	my $self = shift;
	$self->{chromosome} = shift if @_;
	return $self->{chromosome};
}

sub start {
	my $self = shift;
	$self->{start} = shift if @_;
	return $self->{start};
}


sub end {
	my $self = shift;
	$self->{end} = shift if @_;
	return $self->{end};
}

sub strand {
	my $self = shift;
	$self->{strand} = shift if @_;
	return $self->{strand};
}

sub nexons {
	my $self = shift;
	return $self->{nexons};
}

sub source {
	my $self = shift;
	$self->{source} = shift if @_;
	return $self->{source};
}

sub exon_list {
	return @{ shift->{exon_list} };
}

sub add_exon {
	my $self = shift;
	my $exon = shift;
	push @{ $self->{exon_list} }, $exon;
	$self->{exons}->{$exon->id} = $exon;
	$self->{nexons}++;
}

sub get_exon {
	my $self = shift;
	my $n = shift;
	return $self->{exon_list}->[$n];
}

sub get_exon_by_id {
	my $self = shift;
	my $id = shift;
	if (exists $self->{exons}->{$id}) {
		return $self->{exons}->{$id};
	}
	return undef;
}

# stores the nucleotide sequence of the gene.
sub seq {
	my $self = shift;
	$self->{seq} = shift if @_;
	return $self->{seq};
}

# stores the protein sequence of the gene, in any.
sub translation {
	my $self = shift;
	$self->{translation} = shift if @_;
	return $self->{translation};
}

our %QUALITY_SCORE = (
	0 => 'ONE_STAR',
	1 => 'TWO_STARS',
	2 => 'THREE_STARS',
);

sub quality {
	my $self = shift;
	my $eexons = shift;
	
	my $nexons = $self->nexons;
	if ($nexons ==  $eexons) {
		return $QUALITY_SCORE{2};
	} else {
		if ($nexons == 1) {
			# could be a processed pseudogene.
			return $QUALITY_SCORE{1};
		} else {
			return $QUALITY_SCORE{0};
		}
	}
}

1;