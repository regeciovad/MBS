#!/bin/bash
# FLP projekt za rok 2016/2017
# Logicky projekt v jazyce Prolog
# Varianta Patnactka
# Vypracovala Dominika Regeciova, xregec00

make
start=$(date +%s.%N)
./flp17-log < tests/test1.txt > tests/res_test1.txt
runtime=$(echo "$(date +%s.%N) - $start" | bc)
printf "Test1: $runtime s\n"

start=$(date +%s.%N)
./flp17-log < tests/test2.txt > tests/res_test2.txt
runtime=$(echo "$(date +%s.%N) - $start" | bc)
printf "Test2: $runtime s\n"

start=$(date +%s.%N)
./flp17-log < tests/test3.txt > tests/res_test3.txt
runtime=$(echo "$(date +%s.%N) - $start" | bc)
printf "Test3: $runtime s\n"

start=$(date +%s.%N)
./flp17-log < tests/test4.txt > tests/res_test4.txt
runtime=$(echo "$(date +%s.%N) - $start" | bc)
printf "Test4: $runtime s\n"

start=$(date +%s.%N)
./flp17-log < tests/test5.txt > tests/res_test5.txt
runtime=$(echo "$(date +%s.%N) - $start" | bc)
printf "Test5: $runtime s\n"

start=$(date +%s.%N)
./flp17-log < tests/test6.txt > tests/res_test6.txt
runtime=$(echo "$(date +%s.%N) - $start" | bc)
printf "Test6: $runtime s\n"

start=$(date +%s.%N)
./flp17-log < tests/test7.txt > tests/res_test7.txt
runtime=$(echo "$(date +%s.%N) - $start" | bc)
printf "Test7: $runtime s\n"

start=$(date +%s.%N)
./flp17-log < tests/test8.txt > tests/res_test8.txt
runtime=$(echo "$(date +%s.%N) - $start" | bc)
printf "Test8: $runtime s\n"

start=$(date +%s.%N)
./flp17-log < tests/test9.txt > tests/res_test9.txt
runtime=$(echo "$(date +%s.%N) - $start" | bc)
printf "Test9: $runtime s\n"




