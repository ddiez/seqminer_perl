#!/bin/sh

#echo "* formating genome (perl)"
#index_fasta.pl -i genome.fa
#echo "* formating gene (perl)"
#index_fasta.pl -i gene.fa
#echo "* formating protein (perl)"
#index_fasta.pl -i protein.fa
echo "* formating genome (blast)"
formatdb -p F -i genome.fa -n genome -o T -V
echo "* formating gene (blast)"
formatdb -p F -i gene.fa -n gene -o T -V
echo "* formating protein (blast)"
formatdb -i protein.fa -n protein -o T -V
