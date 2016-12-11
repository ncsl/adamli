function serverPerturbationScript(patient, radius, winSize, stepSize, frequency_sampling)for j=1:length(perturbationTypes)
    perturbationType = perturbationTypes(j);

    toSaveFinalDataDir = fullfile(strcat(adjMat, num2str(winSize), ...
    '_step', num2str(stepSize), '_freq', num2str(frequency_sampling)), strcat(perturbationType, '_perturbations', ...
        '_radius', num2str(radius)));
    if ~exist(toSaveFinalDataDir, 'dir')
        mkdir(toSaveFinalDataDir);
    end

    perturb_args = struct();
    perturb_args.perturbationType = perturbationType;
    perturb_args.w_space = w_space;
    perturb_args.radius = radius;
    perturb_args.adjDir = toSaveAdjDir;
    perturb_args.toSaveFinalDataDir = toSaveFinalDataDir;
    perturb_args.TYPE_CONNECTIVITY = TYPE_CONNECTIVITY;
    
    computePerturbations(patient_id, seizure_id, perturb_args); % the icm server perturbation func
%     computePerturbation(patient_id, seizure_id, perturb_args); % the local parallelized perturbation
end
end