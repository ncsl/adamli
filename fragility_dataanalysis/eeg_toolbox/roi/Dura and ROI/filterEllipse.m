function newEllipse = filterEllipse(ellipse,resolution)

connectivity = zeros(size(ellipse,1));
for j = 1:size(ellipse,1)
    pt = ellipse(j,:); % first point
    dist = pdist2(pt,ellipse);
    [~,idx] = sort(dist);
    connectivity(j,:) = idx;
end

res = resolution;
distMat = pdist2(ellipse,ellipse);
track = false(size(ellipse,1),1);
j=1;
newEllipse = ellipse(j,:);
idxUsed = [];
while sum(track == false)
    totDist = 0;
    while totDist <= res
        if sum(track == false)
            relIdx = (connectivity(j,:));
            relIdx = relIdx(2:end);
            relIdx = setdiff(relIdx,idxUsed,'stable');
            d = distMat(j,relIdx(1));
            totDist = totDist + d;
            idxUsed =[idxUsed;j];
            track(j) = 1;
            j = relIdx(1);
            if d<=10 && sum(track)==length(track)-1
                track(j) = 1;
            end
        else
            newEllipse = [newEllipse;ellipse(j,:)];
            break;
        end
        
    end
    if totDist > res
        j = idxUsed(end-1);
        newEllipse = [newEllipse;ellipse(j,:)];
    end
end
