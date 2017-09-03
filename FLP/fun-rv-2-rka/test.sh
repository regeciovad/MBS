#!/bin/bash
# FLP projekt za rok 2016/2017
# Funcionalni projekt v jazyce Haskell
# Varianta rv-2-rka
# Vypracovala Dominika Regeciova, xregec00

for i in `eval echo {1..$1}`; 
do
    ./rv-2-rka -r tests/test$i.in > tests/test$i.diff
    result=$(diff tests/test$i.in tests/test$i.diff)
    if [ $? -ne 0 ]
    then
        echo "Test$i -r ERROR:"
        echo $result
    else
        echo "Test$i -r OK"
    fi

    ./rv-2-rka -t tests/test$i.in > tests/test$i.diff
    result=$(diff tests/test$i.out tests/test$i.diff)
    if [ $? -ne 0 ]
    then
        echo "Test$i -t ERROR:"
        echo $result
    else
        echo "Test$i -t OK"
    fi
done

rm tests/test*.diff



