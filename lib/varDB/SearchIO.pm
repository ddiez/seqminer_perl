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

sub get_organism {
	return shift->{organism};
}

sub get_strain {
	return shift->{strain};
}

sub get_organism_dir {
	return shift->{organism_dir};
}

sub get_super_family {
	return shift->{super_family};
}

sub get_family {
	return shift->{family};
}

sub get_seed {
	return shift->{seed};
}

sub get_pssm_eval {
	return shift->{pssm_eval};
}

sub get_psi_eval {
	return shift->{psi_eval};
}

sub get_tbn_eval {
	return shift->{tbn_eval};
}

sub get_iter {
	return shift->{iter};
}

sub get_hmm_acc {
	return shift->{hmm_acc};
}

sub get_hmm_name {
	return shift->{hmm_name};
}

sub get_hmm_eval {
	return shift->{hmm_eval};
}

sub get_eexons {
	return shift->{eexons};
}

sub get_format {
	return shift->{format};
}

sub debug {
	my $self = shift;
	print STDERR <<"TXT";
----------------------------------------------
 organism: $self->{organism}
 strain:   $self->{strain}
 family:   $self->{family}
----------------------------------------------
TXT

}

1;
