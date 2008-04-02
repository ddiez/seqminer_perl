package varDB::SearchIO;

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
	
	my ($organism, $strain, $organism_dir, $super_family, $family, $seed, $pssm_eval, $psi_eval, $tbn_eval, $iter, $hmm_acc, $hmm_name, $hmm_eval, $eexons, $format) = split '\t', $param;

	$self->{organism} = $organism;
	$self->{strain} = $strain;
	$self->{organism_dir} = $organism_dir;
	$self->{super_family} = $super_family;
	$self->{family} = $family;
	$self->{seed} = $seed;
	$self->{pssm_eval} = $pssm_eval;
	$self->{psi_eval} = $psi_eval;
	$self->{tbn_eval} = $tbn_eval;
	$self->{iter} = $iter;
	$self->{hmm_acc} = $hmm_acc;
	$self->{hmm_name} = $hmm_name;
	$self->{hmm_eval} = $hmm_eval;
	$self->{eexons} = $eexons;
	$self->{format} = $format;
}

sub organism {
	return shift->{organism};
}

sub strain {
	return shift->{strain};
}

sub organism_dir {
	return shift->{organism_dir};
}

sub super_family {
	return shift->{super_family};
}

sub family {
	return shift->{family};
}

sub seed {
	return shift->{seed};
}

sub pssm_eval {
	return shift->{pssm_eval};
}

sub psi_eval {
	return shift->{psi_eval};
}

sub tbn_eval {
	return shift->{tbn_eval};
}

sub iter {
	return shift->{iter};
}

sub hmm_acc {
	return shift->{hmm_acc};
}

sub hmm_name {
	return shift->{hmm_name};
}

sub hmm_eval {
	return shift->{hmm_eval};
}

sub eexons {
	return shift->{eexons};
}

sub format {
	return shift->{format};
}

sub debug {
	my $self = shift;
	print STDERR <<"TXT";
*
* organism: $self->{organism}
* strain: $self->{strain}
* family: $self->{family}
*
TXT

}

1;
