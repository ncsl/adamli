# Degree of Agreement Statistic for EpiMap

## Summary: 
With our research project, we are interested in comparing our results with clinician results. Every patient has a list of:

	* resected labels
	* epileptogenic zone (EZ) labels
	* early onset labels
	* late onset labels

These are clinically important for the physician to know. The code for "Degree of Agreement Statistic" should use the available electrode labels, our predicted EZ labels and the clinical predicted EZ labels to compute a statistic saying how much we agree with clinical annotations. 

## Important Info:
There will be a copy of a master Excel sheet with clinically relevant data, including resected labels and EZ labels. There will be a "outputData" directory that includes final fragility matrices for each patient's seizure. From these matrices, a single predicted number will be outputted to determine the likelihood of an electrode being EZ. The labelled set of all electrodes can be extracted from the .mat files. The clinically labeled EZ electrodes can also be extracted from the .mat files.

-> get predicted likelihood of EZ electrodes, clinically labeled EZ electrodes and all electrode labels.

## Function Requirements:
Inputs:
* clinical EZ labels
* likelihood EZ labels
* all electrode labels

Outputs:
* Degree of Agreement in range [-1, 1]

## Computing Degree of Agreement
The channels whose weights are above α constitute EpiMaps’s ROI, denoted as EROI. The EROI will then be compared to the clinically annotated ROI, denoted as CROI. 

D=(#(CROI∩EROI))/(#CROI) - (#((CROI)^c ∩ EROI))/(#(CROI)^c)          	   (3)
where T^c denotes the complement of set T (where the universe is the set of all channels). D is the difference between the match and mismatch of EpiMap, respectively. Note that D∈[-1,1], where D=1 implies perfect accuracy and D<0 is inaccurate. 


