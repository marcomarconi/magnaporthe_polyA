```console


########
# Pîpeline to reproduce the experiment "Genome-wide polyadenylation site mapping datasets in the rice blast fungus Magnaporthe oryzae"
########

# trim low quality reads, polyA tails and adapters, to be called for the paired-end fastq files
fastq-mcf -o file1_trimmed_1.fastq -o file2_trimmed_2.fastq -0 -l 17 -u adaptor.fa file1.fastq file2.fastq  

    
# build gmap database
gmap_build -d MG8_21 -D ./MG8_21 Magnaporthe_oryzae.MG8.23.gff3

# align, to be repeated for all trimmed files
gsnap -B 5 -t 8 -A sam -d MG8_21 -D ./MG8_21  a_1.fastq a_2.fastq > "${f%%.*}".sam


# convert to bam, extract first reads only, sort and index
for f in `ls *.sam `
do
    samtools view -bS -h -f 0x0040 "${f%%.*}".sam |  samtools sort  -  "${f%%.*}".sorted
    samtools index "${f%%.*}".sorted.bam
done

# filter out low quality mapping, reads with high A/T content and internal priming
for f in `ls *.sorted.bam`
do
    samtools index $f
    python filter.py "${f%%.*}".sorted.bam Magnaporthe_oryzae.MG8.23.dna.toplevel.fa 7 "${f%%.*}".filtered
    samtools index "${f%%.*}".filtered.bam
done

# assign reads to transcripts
for f in `ls *.filtered.bam`
do
    python assign.py Magnaporthe_oryzae.MG8.23.gff3 "${f%%.*}".filtered.bam "${f%%.*}".assign "${f%%.*}".notassign 7
done

# create bedgraphs  
for f in `ls *.assign`
do
    cat  "${f%%.*}".assign | cut -f 2,3,4,5 | awk '{  if ( $4 == "-" ) print $3,$1  }' | sort -n | uniq -c | awk '{ printf "%s\t%d\t%d\t%d\n",$3,$2-1,$2,$1 }' > "${f%%.*}"_plus.bedgraph 
    cat  "${f%%.*}".assign | cut -f 2,3,4,5 | awk '{  if ( $4 == "+" ) print $2,$1  }' | sort -n | uniq -c | awk '{ printf "%s\t%d\t%d\t%d\n",$3,$2-1,$2,$1 }' > "${f%%.*}"_minus.bedgraph
done


# create polyA file
for f in `ls *.assign`
do
    cat "${f%%.*}".assign | cut -f 2,3,4,5,6,7,8 | awk '{  if ( $4 == "+" ) print $2,$1,$4,$5,$6,$7; else print $3,$1,$4,$5,$6,$7  }' | sort -k4 | uniq -c > "${f%%.*}".polyA
done


# gene expression count
cut -f 1 gene_summary.txt  > _t
for f in `ls *.assign`
do
    cut -f 6 $f | cat - _t | sort | uniq -c | awk '{print $2"\t"$1-1}' > "${f%%.*}".expr
done
rm _t 


# extract polyA most significant sites
for f in `ls *.polyA`; do python extract.py Magnaporthe_oryzae.MG8.23.gff3 $f "${f%%.*}".expr 33 0.05 5 all > $f"_"all_m; done 


# cumulate replicates
for f in  "WT-CM" "WT-MM" "WT--N" "WT--C" "2D4-CM" "2D4-MM" "2D4--N" "2D4--C"
do    
    cat $f"-"1.polyA_all_m $f"-"2.polyA_all_m $f"-"3.polyA_all_m |  sort -k 2,7 | uniq -f 1 -c | awk '{if ($1 >= 2) print 0,$3,$4,$5,$6,$7,$8}' > $f"-"X.polyA_all_m
done
cat WT*X*.polyA_all_m |  sort -k 1,7 | uniq  > WT-ALL-X.polyA_all_m
cat 2D4*X*.polyA_all_m |  sort -k 1,7 | uniq  > 2D4-ALL-X.polyA_all_m


# gff of polyA
for f in `ls *.polyA_all_m`; do cut $f -d " " -f 1,2,3,4,5 | awk '{ if ($4 == "+") sense = "-"; else sense = "+"; printf "%s\tmarco\tpolyA_site\t%d\t%d\t.\t%s\t.\ttranscript=%s;value=%d\n", $3, $2, $2, sense, $5, $1  }' > "${f%%.*}"_polyA.gff ; done
for f in `ls *.notpolyA_all_m_high`; do cut $f -d " " -f 1,2,3,4,5 | awk '{ if ($4 == "+") sense = "-"; else sense = "+"; printf "%s\tmarco\tpolyA_site\t%d\t%d\t.\t%s\t.\ttranscript=%s;value=%d\n", $3, $2, $2, sense, $5, $1  }' > "${f%%.*}"_notpolyA_high.gff ; done
for f in `ls *.notpolyA_all_m_low`;  do cut $f -d " " -f 1,2,3,4,5 | awk '{ if ($4 == "+") sense = "-"; else sense = "+"; printf "%s\tmarco\tpolyA_site\t%d\t%d\t.\t%s\t.\ttranscript=%s;value=%d\n", $3, $2, $2, sense, $5, $1  }' > "${f%%.*}"_notpolyA_low.gff ; done


```

