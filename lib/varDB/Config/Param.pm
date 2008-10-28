package varDB::Config::Param;

use strict;
use warnings;

use varDB::Config;
use varDB::TaxonSet;
use varDB::Config::Search;

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
	
	my $ts = new varDB::TaxonSet;
	
	my $file = $VARDB_SEARCH_FILE;
	$file = $param->{file} if defined $param->{file};
	$self->{file} = $file;
	open IN, "$file" or die "$!";
	while (<IN>) {
		next if /^[#|\n]/;
		chomp;
	
		my $info = new varDB::Config::Search($_);
		#print STDERR "* taxonid: ", $info->taxonid, "\n";
		my $taxon = $ts->get_taxon_by_id($info->taxonid);
		$info->organism($taxon->organism);
		$info->strain($taxon->strain);
		$info->organism_dir($taxon->organism_dir);
		push @{ $self->{param_list} }, $info;
		$self->{nparam}++;
	}
	close IN;
	
	$self->{outdir} = "$VARDB_HOME/families/vardb-$VARDB_RELEASE";
	$self->{outdir} = "$VARDB_HOME/families/last" if $DEBUG == 1;
}

sub length {
	return shift->{nparam};
}

{ # other option would be to store n in the class itself.
	my $n = 0;
	sub next_param {
		my $self = shift;
		return $self->{param_list}->[$n++];
	}
	
	sub rewind {
		my $self = shift;
		$n = 0;
	}
}

our @DIRS = ('search', 'analysis', 'sequences', 'pfam', 'fasta', 'domains');

sub create_dir_structure {
	my $self = shift;
	
	$self->{outdir} = "$VARDB_MINING_DIR/vardb-$VARDB_RELEASE";
	if ($DEBUG == 1) {
		my $randir = &_get_random_dir;
		$self->{outdir} = "$VARDB_MINING_DIR/$randir";
	}
	
	# create working directory, die on failure.
	if (! -d $self->{outdir}) {
		mkdir $self->{outdir};
		foreach my $dir (@DIRS) {
			mkdir "$self->{outdir}/$dir";	
		}
	} else {
		die "directory $self->{outdir} already exists!.\n";
	}
	
	chdir $VARDB_MINING_DIR;
	unlink "last";
	system "ln -s $self->{outdir} last";
	
	while (my $info = $self->next_param) {
		foreach my $dir (@DIRS) {
			chdir "$self->{outdir}/$dir";
			mkdir $info->super_family;
		}
	}
	$self->rewind;
}

# this one works in the cwd.
sub create_local_dir_structure {
	my $self = shift;
	
	while (my $info = $self->next_param) {
		foreach my $dir (@DIRS) {
			mkdir $info->super_family;
		}
	}
	$self->rewind;
}

sub dir {
	my $self = shift;
	my $info = shift;
	my $type = shift;
	
	return "$self->{outdir}/$type/".$info->super_family;
}

sub chdir {
	my $self = shift;
	my $info = shift;
	my $type = shift;
	
	my $res = chdir "$self->{outdir}/$type/".$info->super_family;
	die "[SearchParam:chdir] cannot change to dir $self->{outdir}/$type/".$info->super_family if $res == 0;
}

sub debug {
	my $self = shift;
	
	print STDERR "* config_file: $self->{file}\n";
	print STDERR "* output_dir: $self->{outdir}\n";
}

sub _get_random_dir {
	my @time = localtime time;
	$time[5] += 1900;
	$time[4] ++;
	$time[4] = sprintf("%02d", $time[4]);
	$time[3] = sprintf("%02d", $time[3]);
	$time[2] = sprintf("%02d", $time[2]);
	$time[1] = sprintf("%02d", $time[1]);
	$time[0] = sprintf("%02d", $time[0]);
	
	return "$time[5]$time[4]$time[3].$time[2]$time[1]$time[0]";
}

1;
