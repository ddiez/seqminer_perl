package varDB::Config::Dir;

use strict;
use warnings;
use varDB::Config;

my @DIRS = ('search', 'analysis', 'sequences', 'pfam', 'fasta', 'domains');

sub new {
	my $class = shift;
	
	my $self = {};
	bless $self, $class;
    $self->_initialize(@_);
    return $self;
}

sub _initialize {
	my $self = shift;
	$self->{outdir} = $VARDB_SEARCH_DIR;
}

sub create_dir_structure {
	my $self = shift;
	
	# create working directory, die on failure.
	if (! -d $self->{outdir}) {
		mkdir $self->{outdir};
		foreach my $dir (@DIRS) {
			mkdir "$self->{outdir}/$dir";	
		}
	} else {
		die "directory $self->{outdir} already exists!.\n";
	}
	
	unlink "$VARDB_HOME/families/last";
	system "ln -s $self->{outdir} $VARDB_HOME/families/last";
	
	# reads a file containing that info.
	my $og = new varDB::Config::Orthologues;
	foreach my $dir (@DIRS) {
		chdir "$self->{outdir}/$dir";
		foreach my $o ($og->og_list) {
			mkdir $o->name;
		}
	}
}

# this one works in the cwd.
sub create_local_dir_structure {
	my $self = shift;
	
	my $og = new varDB::Config::Orthologues;
	foreach my $dir (@DIRS) {
		foreach my $o ($og->og_list) {
			mkdir $o->name;
		}
	}
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