package varDB::SearchParam;

use strict;
use warnings;

use varDB::Config;
use varDB::SearchIO;

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
	
	my $file = $VARDB_SEARCH_FILE;
	$file = $param->{file} if defined $param->{file};
	$self->{file} = $file;
	open IN, "$file" or die "$!";
	while (<IN>) {
		next if /^[#|\n]/;
		chomp;
	
		my $info = new varDB::SearchIO($_);
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

sub create_dir_structure {
	my $self = shift;
	
	$self->{outdir} = "$VARDB_HOME/families/vardb-$VARDB_RELEASE";
	if ($DEBUG == 1) {
		my $randir = &_get_random_dir;
		$self->{outdir} = "$VARDB_HOME/families/$randir";
	}
	
	# create working directory, die on failure.
	if (! -d $self->{outdir}) {
		mkdir $self->{outdir};
		mkdir "$self->{outdir}/search";
		mkdir "$self->{outdir}/analysis";
		mkdir "$self->{outdir}/nelson";
		mkdir "$self->{outdir}/pfam";
		mkdir "$self->{outdir}/test";
	} else {
		die "directory $self->{outdir} already exists!.\n";
	}
	
	unlink "$VARDB_HOME/families/last";
	system "ln -s $self->{outdir} $VARDB_HOME/families/last";
	
	while (my $info = $self->next_param) {
		chdir "$self->{outdir}/search";
		mkdir $info->super_family;
		chdir "$self->{outdir}/analysis";
		mkdir $info->super_family;
		chdir "$self->{outdir}/nelson";
		mkdir $info->super_family;
		chdir "$self->{outdir}/pfam";
		mkdir $info->super_family;
		chdir "$self->{outdir}/test";
		mkdir $info->super_family;
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
