Progress Report For Adam Li: 1st year

# First Year (August 2015- May 2016)
## Rotation 1 (08/15 - 11/15) Sarma:
During this time period, I used MATLAB and Python to analyze epilepsy Stereoelectroencephalography (SEEG) data. Each patient had the varying channel data condensed into a network. All channels formed a weighted undirected graph between all other channels, with a coherence, or power similarity measure as the weighted edge between vertices. This graph was formed at an averaged time window over the entire time series with an overlap of a certain percentage. 

Once the time series graph was formed, every graph produced an eigenvector centrality measure, which measures how important certain vertices are in the graph. From here, various data mining analyses were done to look for a notion of a pre-ictal state. The following analyses were carried out:

1. Separate the preictal, ictal and postictal stages by +/-5, 10 minutes and then for each stage compute a gap statistic that leads to a statistical way of arriving at optimal k
2. Compute k-means from each and plot state progression 
-> ictal state follows a state progression that is unsupervised and still follows that from publication
-> postictal state follows some sort of state progression
-> preictal was difficult to characterize

## Rotation 2 (11/15 - 01/16) Durr:
Used MATLAB to program a robust photometric stereo algorithm that uses low-rank matrix completion and recovery with Convex Programming. This solved a minimization of a nuclear norm with an l1-regularization term for sparsity. The nuclear norm replaces min(rank(A)), which is an intractable problem. This was solved efficiently using the Augmented Lagrange Multiplier (ALM) method.

Would be difficult to extend to the colonoscopy experiments in the Durr lab because of the limitation on the number of images gathered (n=4 vs. the n=10-20 for sufficient matrix recovery). 

## Rotation 3 (01/16 - 06/16) Zaghloul (NIH):
In this rotation, I investigated a paired word task to study the electrophysiology of basic memory mechanisms in retrieval. We were looking at spectral features of different paired words and the features during retrieval of the correct paired word. 

For example, BRICK might be paired with CLOCK, and then later paired with GLASS. We are interested in determining if there are differences in spectral features in certain areas of the brain that encode these differences in word pair encodings. To analyze this data, we carried out the following procedure:

1. Compute eeg voltage data from all channels
2. Compute the Morlet Wavelet transform on all channels to obtain a power estimate at different frequency bands
-> resulting eeg data from -1 seconds to 5 seconds after probeWord comes on the screen
3. Notch filter at 59.5-60.5 Hz
4. Z-transform with respect to a fixation period (or to the overall signal average signal)
5. Separate all data by session and blocks and word pairs. Then compute a feature vector for all the different word pair groups: same words, reverse words, different words and compute the cosine similarity between these feature vectors. 

## Courses:
#### First Semester:
1. Principles of Biomedical Instrumentation
  - Learned about sensors and biomedical circuitry for denoising and sampling human data (e.g. EEG, ECG, EMG) and creating a ECG/EMG circuit. Heavily exposed to circuit design of instrumentation amplifiers, op-amp circuits, filters and sampling data. 
  - Created an EMG/ECG concurrent sensor circuit with sautered components 
  - Created a Teensyduino controlled prototype with Flexiforce sensors for bio-gaming
2. Principles of Complex Network Theory
3. Applied Mathematics for Science and Engineering
  - Learned about differential equations from ordinary 1st order, 2nd order, fourier series and partial differential equations.
  - Looked at different methods of analytical solving such as, separation of variables, 

#### Second Semester:
1. Honors Instrumentation
  - Built a better prototype for bio-gaming with an improved design
2. The Art of Data Science
  - Worked on a research dataset with features of "predicted" synapses from electron microscopy data
  - Learned about the data science methodology and how to apply various data visualizations, statistical methods and machine learning algorithms to data.
3. Convex Optimization
  - Covered convex analysis and theory, along with algorithms for solving non-smooth (un differentiable), smooth (differentiable) functions
  - Covered Lagrangian duality theory for solving problems and acceleration methods for first-derivative methods. Looked at l1 regularization of objective functions. 
4. Learning Theory
  - Covered Kalman filtering and its relations to solving state-space models, Bayesian inference and optimal feedback control theory
  - Used Bellman equations and Kalman filter to simulate biological systems (e.g. head and eye movements)

## Other Projects:
1. Game Enhanced Augmented Reality (GEAR): A platform for foot control of your computer to reduce tension and increase usability. This project won first place in the National Intel-Corenell Cup and has been featured in news sites such as Popular Science.
2. HopHacks Clinical Search Index (CSI): A web platform for searching for relevant clinical trials related to your disease, which placed first in the best use of Biomedical Data at Hophacks 2016.
