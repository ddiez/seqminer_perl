package varDB::Organism;

use strict;
use warnings;

use varDB::Config;

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
	
	my $file = $VARDB_ORGANISM_FILE;
	$file = $param->{file} if defined $param->{file};
	$self->{file} = $file;
	open IN, "$file" or die "$!";
	while (<IN>) {
		next if /^[#|\n]/;
		chomp;
		my ($taxonid, $organism, $strain) = split '\t', $_;
		my $id = $organism."_".$strain;
		#$id = $organism."_".$strain_view if $strain_view ne "";
		#$id =~ s/(.).+?(\..+)/$1$2/;
		$self->{$taxonid}->{organism} = $organism;
		$self->{$taxonid}->{strain} = $strain;
		#$self->{$id}->{strain_view} = $strain_view;
		#$self->{$taxonid}->{taxonid} = $taxonid;
		push @{ $self->{organism_list} }, $id;
	}
	close IN;
}

sub organism {
	my $self = shift;
	my $id = shift;
	$self->{$id}->{organism} = shift if @_;
	return $self->{$id}->{organism};
}

sub strain {
	my $self = shift;
	my $id = shift;
	$self->{$id}->{strain} = shift if @_;
	return $self->{$id}->{strain};
}

#sub strain_view {
#	my $self = shift;
#	my $id = shift;
#	$self->{$id}->{strain_view} = shift if @_;
#	return $self->{$id}->{strain_view};
#}

sub taxonid {
	my $self = shift;
	my $id = shift;
	$self->{$id}->{taxonid} = shift if @_;
	return $self->{$id}->{taxonid};
}

sub organism_list {
	return shift->{organism_list};
}

1;
