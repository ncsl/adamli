#!/bin/bash

source /etc/profile.modules
module load matlab/matlab2013a

cd /projects/sarma/cluster_script_example
pwd

matlab -logfile /projects/sarma/cluster_script_example/_log/test$1.txt -nojvm -nodisplay -nosplash -r "helper_test_m($1,$2);exit"