# American Control Conference 2017
## By: Adam Li | adam2392@gmail.com
Reference:

This paper analyzes two epileptic patients from iEEG recordings collected from the NIH. We analyzed 2 seizures from each patient. The patient identifiers analyzed were:
    * pt1sz2
    * pt1sz3
    * pt2sz1
    * pt2sz3
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

Perturbation Computation:
Parameters:
* radius = 1.5

Now plot fragility as described in the paper.


