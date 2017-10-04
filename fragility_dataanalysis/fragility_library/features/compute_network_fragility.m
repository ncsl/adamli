function [network_fragility] = compute_network_fragility(fragilityMat)
    network_fragility = nansum(fragilityMat, 1);
end