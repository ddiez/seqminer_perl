package varDB::Parser::plasmodb;

use varDB::Parser;
@ISA = qw(varDB::Parser);

use strict;
use warnings;

sub new {
	my $class = shift;
	
	# check file type passed.
	
	# if it is a sequence file, call SUPER to load it.
	my $self = $class->SUPER::new(@_);
	
	# if not, load it properly.
	
	# add class specific slots.
	
	bless $self, $class;
	
	return $self;
}

# read the data and store it into the proper fields.
sub process {
	my $self = shift;
	
	if ($self->type eq "gene" or $self->type eq "protein") {
		#
	} elsif ($self->type eq "genome") {
		#
	} elsif ($self->type eq "position") {
		#
	}
}

# save the data with the correct format.
sub dump {
	my $self = shift;
	
	# FIXME.
}

1;
