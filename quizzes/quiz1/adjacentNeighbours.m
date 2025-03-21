clear;
clc;

% loads image
birds = imread('birds.tif');


% variables to change
pixel = [67,45];
threshold = 2;

%---------- PRE-PROCESSING ----------%
[maxRow, maxCol] = size(birds);

greyVal = birds(pixel(1),pixel(2)); %grey value of the chosen pixel
N4 = [-1, 0;  1, 0; 0, -1; 0, 1]; % up, down, left, right

%---------- IMPLEMENTATION ----------%   
l = zeros(size(birds)); %matrix of 0s same size as original image, since all pixels 0 but nearest N4 neighbours
l(pixel(1),pixel(2)) = 1; %sets original pixel value to 1

B = [pixel];

while ~isempty(B)

    q = B(1,:); %sets q to the first pixel stored in B
    B(1,:) = []; %removes first pixel in B
   
    % checks N4 neighbours
    for i = 1:4
        nR = q(1) + N4(i, 1); %neighbouring pixel row
        nC = q(2) + N4(i, 2); %neighbouring pixel column
    
        % checks if assigned neighbouring pixel exists in image
        if ((nR >= 1 && nR <= maxRow) && (nC >= 1 && nC <= maxCol))
    
            %checks we haven't already checked the pixel, to prevent infinite loops
            if ((l(nR,nC) == 0) && (abs(greyVal - birds(nR, nC)) < threshold))
    
                B = [B; nR,nC]; %adds neighbouring pixel to B matrix, to check its neighbours
                l(nR, nC) = 1; %updates neighbouring pixel value in l matrix

            end
        end
    end
end

figure;
imshow(l * 255); %creates image w/ white pixels that are adjacent to "pixel", and black otherwise



