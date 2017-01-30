function saveChannel(toSaveDir, chanFileName, data)
    save(fullfile(toSaveDir, chanFileName), 'data');  
end