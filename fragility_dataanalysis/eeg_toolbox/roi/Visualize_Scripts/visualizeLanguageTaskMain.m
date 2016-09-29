function visualizeLanguageTaskMain(homeDir, filename, sentWordMat, fabWordMat, fabSentMat,corticalSurfROI)

load(fullfile(homeDir,'LanguageTask/Matlab Analysis/All Purpose/LT_toolbox/Data_Processing/Power/relVerts.mat'));
idx = relVerts; % relVerts contains what vertices fall under each ROI
bandSymbols = {'theta','alpha','beta','low gamma','high gamma'};
views = {[-90 0],[90 0],[-180 90],[180 -90],[180 0]};
zoom_factor = 2;
for i=1:5
    for currentView = 1:5
        handle = figure;
        set(handle,'PaperUnits','normalized');
        set(handle, 'PaperPosition', [0 0 1 1]);
        h1 = subplot(3,1,1);
        hBrain1 = visualizeLanguageTask(homeDir,idx,sentWordMat(:,i),corticalSurfROI);
        view(views{currentView}); title([texlabel(bandSymbols{i}) ', sentence-word']);
        h2 = subplot(3,1,2);
        hBrain2 = visualizeLanguageTask(homeDir,idx,fabWordMat(:,i),corticalSurfROI);
        view(views{currentView}); title([texlabel(bandSymbols{i}) ', fable-word']);
        h3 = subplot(3,1,3);
        hBrain3 = visualizeLanguageTask(homeDir,idx,fabSentMat(:,i),corticalSurfROI);
        view(views{currentView}); title([texlabel(bandSymbols{i}) ', fable-sentence']);
        camzoom(h1,zoom_factor);camzoom(h2,zoom_factor);camzoom(h3,zoom_factor)
        print(handle,'-dpsc','-append',filename);
        close all
    end
end