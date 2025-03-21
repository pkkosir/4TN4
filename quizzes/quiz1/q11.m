clear;
clc;

% loads image
origRace = imread('race.tif');
race = double(origRace); %converted to double for operations

%masks
avgMask = 1/16 * [1, 2, 1; 2, 4, 2; 1, 2, 1]; %weighted average
lapMask = [0, -1, 0; -1, 5, -1; 0, -1, 0]; %composite laplacian (w/ 5 in centre)
sobelXMask = [-1, 0, 1; -2, 0, 2; -1, 0, 1]; %sobel X
sobelYMask = [-1, -2, -1; 0, 0, 0; 1, 2, 1]; %sobel Y

%convolutions of mask, taken absolute value and converted to int
average = uint8(conv2(race, avgMask));
laplacian = uint8(abs(conv2(race, lapMask)));
sobelX = uint8(abs(conv2(race, sobelXMask)));
sobelY = uint8(abs(conv2(race, sobelYMask)));

%----------- PLOTTING -----------%

figure;
subplot(1,5,1), imshow(origRace), title('Race');
subplot(1,5,2), imshow((average)), title('Weighted Average');
subplot(1,5,3), imshow(laplacian), title('Composite Laplacian');
subplot(1,5,4), imshow(sobelX), title('Sobel X-Derivative');
subplot(1,5,5), imshow(sobelY), title('Sobel Y-Derivative');

