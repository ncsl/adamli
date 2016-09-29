function ellipse2 = surfaceSmoother(ellipse)
%interpolates points over sulci to create smoother surface

pairDists = pdist(ellipse);
pairDists = squareform(pairDists);
consecDists = [diag(pairDists,1);pairDists(end,1)];

ellipse2 = ellipse;

for j = 1:length(consecDists)-1
   if consecDists(j)>.5
       x = [ellipse(j,1) ellipse(j+1,1)];
       z = [ellipse(j,3) ellipse(j+1,3)];
       X=ellipse(j,1):-.1:ellipse(j+1,1);
       if length(X) == 1
           Z = z(1):.1:z(2);
           X = repmat(X,1,length(Z));
       else
           Z=interp1(x,z,X);
       end
       Y = repmat(ellipse(j,2),1,length(Z));
       pts = [X;Y;Z];
       pts = pts';
   end
   ellipse2 = [ellipse2(1:j,:);pts;ellipse2(j+1:end,:)];
end