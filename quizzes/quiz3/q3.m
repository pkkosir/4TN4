clear;
clc;

leaf = imread('leaf.tif'); 


[counts, greyVals] = imhist(leaf); % histogram of each value reading (counts) and associated gre-values (0-255)
prob = counts/sum(counts); % probability of each histogram value (notice, white aka 255 is over half the image)

mean = sum(greyVals .* prob); % mean value of the whole image

maxVar = 0;
thresh = 0;

for t=1:length(greyVals)
    w0 = sum(prob(1:t)); % probability of background
    w1 = 1 - w0; % prob of foreground, probability of both is always 1

    m0 = sum(greyVals(1:t) .* prob(1:t))  / w0; % mean of background
    m1 = sum(greyVals(t+1:end) .* prob(t+1:end)) / w1; % mean of foreground

    var = w0*w1*(m0-m1)^2; % between-class variance; want highest variance since we know that means we have the best separation between the classes

    if var > maxVar
       maxVar = var; % updates new max variance if the new variance is higher than before
       thresh = greyVals(t); % sets new threshold value to higher grey value for higher variance
    end
end

binLeaf = leaf > thresh;


figure;
subplot(1,3,1); imshow(leaf); title('Leaf');
subplot(1,3,2); imhist(leaf); 
line([thresh, thresh], ylim, 'Color', 'r'); 
title('Histogram w/ Optimal Threshold');
subplot(1,3,3); imshow(binLeaf); title('Binarized Leaf');
