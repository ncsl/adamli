function mat2 = removeBipol(mat)

count =1;
for j = 1:size(mat,1)
    if (mat(j,1)+8 == mat(j,2))||(mat(j,1)+1 == mat(j,2))
        mat2(count,:) = mat(j,:);
        count = count+1;
    end
end