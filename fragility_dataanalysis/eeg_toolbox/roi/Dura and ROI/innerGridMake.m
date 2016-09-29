function [innerMesh, ellipse2] = innerGridMake(eeg_toolDir,brainType,ellipse,type,hemi,inter)


load(fullfile(eeg_toolDir, 'trunk/roi/Pial Surfaces',brainType, [hemi '_hemisphere.mat']))
innerMesh = [];
switch type % the slice type that is being used to construct the inner mesh
    case 'coronal'
        y = ellipse(1,2);
        res = 1;
        % project ellipse onto surface
        
        surf = v(abs(v(:,2)-y)<=res,:);
        d = pdist2(ellipse,surf);
        [~,idx] = sort(d,2);
        if ~isempty(idx)
            ellipse3 = surf(idx(:,1),:);
%             ellipse2(:,2) = ellipse(:,2);
            ellipse3 = unique(ellipse3,'rows');
            % get the max and min x-vals of the ellipse in question
            xMax = max(ellipse3(:,1));
            xMax = xMax;
            xMin = min(ellipse3(:,1));
            xMin = xMin;
            
            % choose an interval with which to iterate through the x-values
            % at each x interval find the maximum and minimum point on the
            % brain surface
            
            
            for x = xMin:inter:xMax
                rel_verts = v(abs(v(:,1)-x)<res & abs(v(:,2)-y)<res,:);
                zMin = min(rel_verts(:,3));
                zMax = max(rel_verts(:,3));
                % shrink points in a litte
                zMax = zMax;
                zMin = zMin;
                % then create evenly spaced points between the max and min points
                zVals = zMin:inter:zMax;
                xVals = repmat(x,size(zVals));
                yVals =  repmat(y,size(zVals));
                mesh = [xVals' yVals' zVals'];
                innerMesh = [innerMesh;mesh];
            end
            ellipse2 = roiFilt(ellipse,inter);
            ellipse2(:,2) = y;
            % remove all points that are within 10 mm of the ellipse
            foo = zeros(1,size(innerMesh,1));
            d2 = pdist2(ellipse2,innerMesh);
            for j = 1:size(ellipse2,1)
                idx = d2(j,:)<=inter;
                foo = foo+idx;
            end
            foo2 = ~foo;
            innerMesh = innerMesh(foo2,:);
            % filter rest of points
            innerMesh = roiFilt(innerMesh,inter);
        else
            innerMesh = [];
            ellipse2 = [];
        end
    case 'sagittal'
        x = ellipse(1,1);
        % get the max and min x-vals of the ellipse in question
        yMax = max(ellipse(:,1));
        yMin = min(ellipse(:,1));
        % choose an interval with which to iterate through the x-values
        inter = 10;
        % at each x interval find the maximum and minimum point on the
        % brain surface
        
        res = 1;
        for y = yMin:inter:yMax
            rel_verts = v(abs(v(:,1)-x)<res & abs(v(:,2)-y)<res,:);
            zMin = min(rel_verts(:,3));
            zMax = max(rel_verts(:,3));
            % shrink points in a litte
            zMax = zMax-5;
            zMin = zMin+5;
            % then create evenly spaced points between the max and min points
            zVals = zMin:inter:zMax;
            xVals = repmat(x,size(zVals));
            yVals =  repmat(y,size(zVals));
            mesh = [xVals' yVals' zVals'];
            innerMesh = [innerMesh;mesh];
        end
end
    

    
    

