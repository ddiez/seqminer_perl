package varDB::R;

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
}

sub barplot {
	my $self = shift;
	my $dir = shift;
	my $file = shift;
	my $title = shift;
	
	my $R =<<"RSCRIPT";

foo <- read.table("$dir/$file", skip = 1)
foo <- foo[order(foo[,2], decreasing = TRUE), ]
pdf(file = "$dir/$file.pdf", width = 5, height = 5)
barplot(foo[,2], names = foo[,1], las = 2, cex.names = 0.8, col = "gray15")
title("$title")
dev.off()
	
RSCRIPT

	open OUT, ">$dir/$file.R" or die "$!";
	print OUT $R;
	close OUT;

	system "R CMD BATCH $dir/$file.R";
}

1;