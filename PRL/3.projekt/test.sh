#!/bin/bash

# Projekt cislo 3, PRL 2016/2017
# Dominika Regeciova, xregec00

fmat1=mat1;
fmat2=mat2;

rows_mat1=$(head -n1 $fmat1)
cols_mat2=$(head -n1 $fmat2)

# Pridana kontrola matic pred spustenim programu

# Kontrola za jsou matice tvaru mat1(m x n), mat2(n x k)
cols_mat1=$(tac $fmat1 | grep -m 1 '.' | wc -w)
rows_mat2=$(sed -n '/[^[:space:]]/p' $fmat2 | wc -l)
rows_mat2=$(($rows_mat2 - 1))
if [ $cols_mat1 != $rows_mat2 ]
then
    echo "Vypocet nelze provest kvuli spatnym rozmerum matic!"
    exit
fi

cpus=$((rows_mat1 * cols_mat2))
 
mpic++ --prefix /usr/local/share/OpenMPI -o mm mm.cpp -std=c++0x
mpirun --prefix /usr/local/share/OpenMPI -np $cpus mm $fmat1 $rows_mat1 $cols_mat1 $fmat2 $rows_mat2 $cols_mat2 
# To Do: Odstrani po otestovani
#mpirun --prefix /usr/local/share/OpenMPI -np $cpus mm $mat1 $cols_mat1 $mat2 

# Uklid
rm -f mm
