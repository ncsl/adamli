# Data Mining Procedure
By: Adam Li

This will be a general data mining procedure done on any dataset.

## 1. Descriptive
- format of data
- nans/infs inside data?
- # of features
- # of samples
- bounds of data
- categorical
- labels of data?
- is there missing data elements? If so, which subjects, or datasets?

## 2. Exploratory
- marginal histograms of data features to understand distribution
- heatmap of features
- scatterplots/paired scatter plots
- dimensional reduction -> PCA and scree plots
- scale data / normalize data
- transformations (log, log-normalized, square root, square root normalized)
- covariance matrix between features
- correlation matrix between features

## 3. Inferential
- test if distributions are different from cluster to cluster? -> use ks 2 sample test for test on median
- test if means are different -> Hotelling's test (multivariate t-test)
- cluster using k-means and plot BIC/DIC/ARI plots -> check using covariance matrix and scatter plot of the cluster points
- 

## 4. Prediction
- define a loss/objective function
- feature selection using forward/backward 
- random forest
- logistic regression
