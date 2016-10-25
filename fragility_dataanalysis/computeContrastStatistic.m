function contrastStat = computeContrastStatistic(patient, radiusList)

if nargin==0
    patient='pt1sz2';
    radiusList = [1.1, 1.2, 1.5, 2.0];
end

% loop through each radius and read in data and compute contrast statistic
for iR=1:length(radiusList)
    currentRadius = radiusList(iR);
end