# Fragility Data Analysis Work Plan and Documentation

## Workplan:
1. Update Functions In Matlab/Python:
	- turn scripts to compute adj. mats, and compute perturbations into functions  []
	- add parallization, so that it can run on Marcc, or ICM server
2. Explore Parameters of Algorithm:
	- run analysis for varying radius, winSize, stepSize, row, column for 1 patient to determine influence of each parameter.
	- Determine optimal set of parameters that determine electrodes in the EZ
3. Run Analysis On NIH/JHU:
	- run analysis on all NIH patients
	- JHU patients to explore differences between grid and strip electrode patients
4. run analysis on cleveland SEEG patients

### Additional Ideas:
1. Different ways of generating connectivity between electrodes 
	- Pearson correlation
	- power coherence

2. Adding regularization to the least squares computation of $||x-\hat{x}||_2$ is minimized. Can include l1, l2, or elastic net.
	- 

3. Using other system identification methods that scale with size (MR.SID).


## Documentation:
File descriptions:
1. computeAdjMats:
This function takes a time range of EEG data, step size, window size and computes an adjacency matrix, A for each window using a vector autoregression model.

The function should also receive the input of EEG data, included_channels, ezone_channels, earlyspread_channels, latespread_channels. This data can be saved correspondingly into a .mat file in a new processed data directory.

2. computePerturbations:
FUNCTION: computePerturbations
DESCRIPTION: This function takes adjacency matrices and computes the
minimum l2-norm perturbation required to destabilize the system.

INPUT:
- patient_id = The id of the patient (e.g. pt1, JH105, UMMC001)
- seizure_id = the id of the seizure (e.g. sz1, sz3)
- w_space = the frequency space on unit disc that we want to search over
- radius = the radius of disc that we want to perturb eigenvalues to
- perturbationType = 'R', or 'C' for row or column perturbation

3. 