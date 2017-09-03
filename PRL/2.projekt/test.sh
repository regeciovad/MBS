#!/bin/bash

# Projetk cislo 2, PRL 2016/2017
# Dominika Regeciova, xregec00

# Zpracovani parametru
if [ $# -eq 1 ]
then
    numbers=$1;
    procNum=$(($numbers + 1))
else
    exit;
fi;

# Preklad
mpic++ --prefix /usr/local/share/OpenMPI -o es es.cpp

# Vyrobeni souboru s random cisly
dd if=/dev/random bs=1 count=$numbers of=numbers

# Spusteni
mpirun --prefix /usr/local/share/OpenMPI -np $procNum es

# Uklid
rm -f es numbers
