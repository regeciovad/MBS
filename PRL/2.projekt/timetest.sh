#!/bin/bash

for (( n=1; n<=25; n++ ))
do
    for (( k=1; k<=10; k++ ))
    do
        ./test.sh $n >> time$n
    done
    Rscript -e 'd<-scan("stdin", quiet=TRUE)' -e 'cat(mean(d), sep="\n")' < time$n >> time
done

