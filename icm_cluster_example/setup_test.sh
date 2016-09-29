#!/bin/bash
clear

# query for input
printf "Enter parameter for test: "
read param

# pass in the parameter as param in the pbs file
qsub -v param=$param run_test.pbs