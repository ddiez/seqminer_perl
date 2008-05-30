#!/bin/sh

files=$@

if [ $files == "" ]
then
	files=`ls -d *`
fi

# initial support for ncbi genbank files.
ocd=`pwd`
cd /Volumes/Data/projects/vardb/db/ncbi/

cwd=`pwd`
epoch=`date "+%Y%m%d%H%M.%S"`
backup_dir=/Volumes/Data/projects/vardb/backup/$epoch
if [ -d $backup_dir ]
then
	rm -rf $backup_dir
fi
mkdir $backup_dir

for kk in $files
do
	if [ -d $kk ]
	then
		echo "* processing genome $kk ... "
		cd $kk
		outdir=/Volumes/Data/projects/vardb/db/genomes/$kk
		mv $outdir $backup_dir
		mkdir $outdir
		seq=`ls *.gbk`
		if [ -e $seq ]
		then
			echo "* getting data "
			vardb_ncbi_parse.pl -i $seq -d $outdir
			cd $outdir
			echo "* formating genome (perl)"
			index_fasta.pl -i genome.fa
			echo "* formating gene (perl)"
			index_fasta.pl -i gene.fa
			echo "* formating protein (perl)"
			index_fasta.pl -i protein.fa
			echo "* formating genome (blast)"
			formatdb -p F -i genome.fa -n genome
			echo "* formating gene (blast"
			formatdb -p F -i gene.fa -n gene
			echo "* formating protein (blast)"
			formatdb -i protein.fa -n protein
			cd $cwd
		fi
	fi
done

cd $ocd
