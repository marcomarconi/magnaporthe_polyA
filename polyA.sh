for f in `ls *.notassign`
do
    cat "${f%%.*}".notassign | cut -f 2,3,4,5,6,7,8 | awk '{  if ( $4 == "+" ) print $2,$1,$4,$5,$6,$7; else print $3,$1,$4,$5,$6,$7  }' | sort -k4 | uniq -c > "${f%%.*}".notpolyA
done

# gene expression count

#cat Magnaporthe_oryzae.MG8.18.gff3 | awk '{if($3 == "gene") print $0}' | grep  "ID=.*;"  -o | sed -e 's/ID=//' -e 's/;//' > _t
cut -f 1 gene_summary.txt  > _t
for f in `ls *.assign`
do
    cut -f 6 $f | cat - _t | sort | uniq -c | awk '{print $2"\t"$1-1}' > "${f%%.*}".expr
done
rm _t 
