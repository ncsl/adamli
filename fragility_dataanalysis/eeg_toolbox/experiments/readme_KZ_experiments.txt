
KZ_experiments Readme.txt


This folder contains m-files for extracting behavioral events for all experiments in the Zaghloul lab.  

Each experiment has its own subdirectory. that should contain, at minimum, a task-specific m-file for extracting a session.log files to an events.mat structure.   Additionally, the subdirectories may contain wrapper functions, etc that call upon the task-specific extraction m-files for a single task.

At the root level of the KZ_experiments directory you can find wrapper functions that call on the task-specific extraction m-files.