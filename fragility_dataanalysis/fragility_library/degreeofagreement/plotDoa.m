FONTSIZE = 20;

figure;
numSubPlots = ceil(length(patients)/5) * 5;
for iPat=1:length(patients)
    patient = patients{iPat};
    
    subplot(5, numSubPlots/5, iPat);
    
    dataToPlot = containers.Map();
    for iThresh=1:length(thresholds)
        threshold = thresholds(iThresh);
        fieldname = strcat('threshold_', num2str(threshold*100));
        
        for iMetric=1:length(metrics)
            metric = metrics{iMetric};
            
            data = doa.(fieldname).(metric);
            val = values(data, {patient});
            if ~isKey(dataToPlot, metric)
                dataToPlot(metric) = [val{1}];
            else
                disp('here')
                dataToPlot(metric) = [dataToPlot(metric) val{1}];
            end
        end
    end
    hold on;
    for iMetric=1:length(metrics)
        metric = metrics{iMetric};
        plot(thresholds, dataToPlot(metric), 'o'); hold on;
    end
    title([patient]);
    xlabel('Thresholds');
    ylabel({'Degree of', 'Agreement'});
    axis tight
    axes = gca;
    axes.FontSize = FONTSIZE;
end