function clinical_struct = getClinicalIndices(included_labels, ezone_labels,...
                    earlyspread_labels, latespread_labels, resection_labels)

% Get Indices for All Clinical Annotations (EZ, early spread, and late
% spread)
ezone_indices = findElectrodeIndices(ezone_labels, included_labels);
earlyspread_indices = findElectrodeIndices(earlyspread_labels, included_labels);
latespread_indices = findElectrodeIndices(latespread_labels, included_labels);

% get indices along the channel axis
allYTicks = 1:length(included_labels); 
y_indices = setdiff(allYTicks, [ezone_indices; earlyspread_indices]);
if sum(latespread_indices > 0)
    latespread_indices(latespread_indices ==0) = [];
    y_indices = setdiff(allYTicks, [ezone_indices; earlyspread_indices; latespread_indices]);
end
y_ezoneindices = sort(ezone_indices);
y_earlyspreadindices = sort(earlyspread_indices);
y_latespreadindices = sort(latespread_indices);

% find resection indices
% y_resectionindices = findResectionIndices(included_labels, resection_labels);
y_resectionindices = [];

% create struct for clinical indices
clinical_struct.all_indices = y_indices;
clinical_struct.ezone_indices = y_ezoneindices;
clinical_struct.earlyspread_indices = y_earlyspreadindices;
clinical_struct.latespread_indices = y_latespreadindices;
clinical_struct.resection_indices = y_resectionindices;
clinical_struct.included_labels = included_labels;
end