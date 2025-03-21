clear;
clc;

%loads images
lena = imread('lena.tif');
camera = imread('cman.tif');

%----------------------------------%
%----------- Question 5 -----------%
%----------------------------------%
%------------- Part 1 -------------%


%---------- DOWN-SCALING ----------%
% Method 1: Taking every 3rd/5th pixel, dividing number of total pixels
lena3div = lena(1:3:end, 1:3:end);
camera3div = camera(1:3:end, 1:3:end);

lena5div = lena(1:5:end, 1:5:end);
camera5div = camera(1:5:end, 1:5:end);

% Method 2: Using built in imresize() function w/ nearest neighbour
lena3res = imresize(lena,1/3,'nearest');
camera3res = imresize(camera,1/3,'nearest');

lena5res = imresize(lena,1/5,'nearest');
camera5res = imresize(camera,1/5,'nearest');
% NOTE: nearest neighbour is the worst, but fastest algorithm so I chose it since I thought it would best 
% compete w/ just taking every Xth pixel

%----------- PLOTTING -----------%
figure(1);

subplot(2,5,1), imshow(lena), title('Lena');
subplot(2,5,2), imshow(lena3div), title('Divided by 3');
subplot(2,5,3), imshow(lena5div), title('Divided by 5');
subplot(2,5,4), imshow(lena3res), title('Resized by 3');
subplot(2,5,5), imshow(lena5res), title('Resized by 5');

subplot(2,5,6), imshow(camera), title('Cameraman');
subplot(2,5,7), imshow(camera3div), title('Divided by 3');
subplot(2,5,8), imshow(camera5div), title('Divided by 5');
subplot(2,5,9), imshow(camera3res), title('Resized by 3');
subplot(2,5,10), imshow(camera5res), title('Resized by 5');


%------------- Part 2 -------------%

%------ REDUCING GREY LEVELS ------%

% divides the grey values by X, rounds to the floor to get an integer, then multiply by the divisor to rescale
% to full dynamic range (reduces available pixels by factor of X)
lena2 = uint8(floor(double(lena)/(2)) * (2)); %closest value divisible by 2
lena4 = uint8(floor(double(lena)/(4)) * (4)); %closest value divisible by 4
lena8 = uint8(floor(double(lena)/(8)) * (8)); %closest value divisible by 8

%----------- PLOTTING -----------%
figure(2);
subplot(1,4,1), imshow(lena), title('Lena');
subplot(1,4,2), imshow(lena2), title('Grey Reduced by 2');
subplot(1,4,3), imshow(lena4), title('Grey Reduced by 4');
subplot(1,4,4), imshow(lena8), title('Grey Reduced by 8');


%----------------------------------%
%----------- Question 6 -----------%
%----------------------------------%

% we want to rotate not using internal commands, but instead the affine  matrix
theta = deg2rad(30);

rotMat = [cos(theta),  sin(theta), 0;
          -sin(theta), cos(theta), 0;
          0,           0,          1];

T = affinetform2d(rotMat); %allows for forward/inverse mapping
centerOut = affineOutputView(size(lena),T,"BoundsStyle","CenterOutput");
followOut = affineOutputView(size(lena),T,"BoundsStyle","FollowOutput");

rotLenaC = imwarp(lena, T, "OutputView", centerOut);
rotLenaS = imwarp(lena, T, "OutputView", followOut);


%----------- PLOTTING -----------%
figure(3);
subplot(1,3,1), imshow(lena), title('Lena');
subplot(1,3,2), imshow(rotLenaC), title('Rotated by 30 deg CCW, Cropped');
subplot(1,3,3), imshow(rotLenaS), title('Rotated by 30 deg CCW, Shrunk');