# Engineering in Medicine and Biology Conference 2017
## By: Adam Li | adam2392@gmail.com
Reference:

This paper analyzes two epileptic patients from iEEG recordings collected from the NIH and Cleveland Clinic. We analyzed 1 seizure from each patient. The patient identifiers analyzed were:
    * pt1sz4
    * EZT019seiz001
Request data by email.

## Pipeline Run:
This describes how to reproduce the results. There are two phases: creating LTV model of iEEG data and computing a fragility map

Filter Data
Parameters:
* [59.5 60.5] notch filter

Compute Connectivity
Parameters:
* winSize = 500
* stepSize = 500
* -60 seconds to seizure onset electrographic

From the adjacency matrix computed, reconstruct data from each window and then log the mean squared error. Use the matlab script in this directory to recreate the plots.

