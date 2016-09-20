# Fragility Data Analysis Work Plan and Documentation

## Workplan:
1. Update Functions In Matlab/Python:
	- turn scripts to compute adj. mats, and compute perturbations into functions  []
	- add parallization, so that it can run on Marcc, or ICM server
	- create notebooks documenting different explorations of data analysis
2. Explore Parameters of Algorithm:
	- run analysis for varying radius, winSize, stepSize, row, column for 1 patient to determine influence of each parameter.
	- Determine optimal set of parameters that determine electrodes in the EZ
3. Run Analysis On NIH/JHU:
	- run analysis on all NIH patients
	- JHU patients to explore differences between grid and strip electrode patients
4. run analysis on cleveland SEEG patients

5. Develop Fragility Statistic:
	- develop a better statistic for comparing electrodes. Would be best if it could come up with a probability of electrode being in EZ with some sort of confidence interval. 

6. How sensitive are these measures to what channels are included?
	- can we automatically reject channels?
	- automate selection of channels better then what EZTrack currently has -> makes things easier to run for new patients

### Additional Ideas:
1. Different ways of generating connectivity between electrodes 
	- Pearson correlation
	- power coherence

2. Adding regularization to the least squares computation of $||x-\hat{x}||_2$ is minimized. Can include l1, l2, or elastic net.
	- 

3. Using other system identification methods that scale with size (MR.SID).

## Workflow:

1. Obtain data:
Here, we want to obtain data from any of the clinical centers we work with. JHU, UMMC, NIH, or Cleveland. There exists code to convert edf file formats into .csv files, which can then be read by MATLAB/Python/R. Contact someone to get access to the server to sftp data onto your workstation.

2. Create patient metafile:
For every patient, we need to create a file outlining when the seizure starts, ends, and length of the eeg file. Then we also need to create a vector of the necessary included channels.
- exclude channels with significant noise, or related to other physiological signatures (e.g. EKG)

3. Put data into correct directories

4. Compute adjacency matrices:
Using the function documented, compute an adjacency matrix.

5. Compute the minimum perturbation to instability.

6. Compute fragility metric and rank electrodes.

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
