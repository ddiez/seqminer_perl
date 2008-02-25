package varDB::Parser::kegg;

@ISA "varDB::Parser";

sub new {
	my $class = shift;
	
	my $self = SUPER->$self->new(@_);
	
	return $self;
}