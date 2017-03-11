patients = {
    'pt11sz1', 'pt11sz2', 'pt11sz3', 'pt11sz4',...
    'pt15sz1', 'pt15sz2', 'pt15sz3', 'pt15sz4',...
    };

winSize = 500;
stepSize = 500;
radius = 1.5;
for iPat=1:length(patients)
    patient=patients{iPat};
    serverAdjMainScript(patient, winSize, stepSize);
    serverPerturbationScript(patient, radius, winSize, stepSize);
end