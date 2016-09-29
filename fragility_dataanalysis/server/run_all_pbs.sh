#!/bin/bash -l

chmod -R 777 .

qsub -l walltime=24:00:00,nodes=node054 run_b_sleep.sh
qsub -l walltime=24:00:00,nodes=node215 run_b_sleep.sh
qsub -l walltime=24:00:00,nodes=node232 run_b_sleep.sh

for i in `find ./ -name '*.pbs'` ; 
do qsub $i ;  
done
