clear;
clc;

lena = imread('lena.tif');
lena = im2double(lena); % for processing purposes, otherwise just get white display

trans = fft2(lena); % fast fourier transform
transZero = abs(trans); % sets phase to 0, since 0-phase -> |F|*e^(i*phi) where phi = 0 therefore |F|
lenaZero = ifft2(transZero); % inverse fast fourier transform

% plotting
figure;
subplot(1, 2, 1); imshow(lena);
title('Lena');

subplot(1, 2, 2); imshow(lenaZero);
title('Lena w/ 0 Phase');


% SECOND PART
elaine = imread("elaine.tif");

trans = fft2(double(elaine)); 
tShift = fftshift(trans); % shifts zero-frequency component to centre to simplify process

cutoff = [30 60 90];
[m, n] = size(elaine);
xCent = m/2;
yCent = n/2;

[x, y] = meshgrid(1:n, 1:m); % meshgrid to determine freq coordinates
dist = sqrt((x-xCent).^2 + (y-yCent).^2); % distance from the centre for each freq component

lap = (x-xCent).^2 + (y-yCent).^2; % lapacian square distance
alpha = 1.1; % alpha value used in laplacian filter
boostKernel = 1 + alpha*lap; % kernel for Boost Filtering 

for cf = cutoff
    
    mask = double(dist <= cf); % evaluates to 1 if within cutoff, otherwise 0
    
    % apply filter
    filt = tShift .* mask;
    
    elaineFilt = ifft2(ifftshift(filt)); % inverse FFT, with IFFT shift to undo original shift
    elaineFilt = real(elaineFilt); % needed so that we can display
    
    % display the filtered image
    figure;
    imshow(elaineFilt, []);
    title(['Filtered Image, CF=', num2str(cf)]);

    % laplacian filter and high-boosting
    transLap = filt .* boostKernel; % applies High Boost laplacian variation
    elaineBoost = ifft2(ifftshift(transLap));
    elaineBoost = real(elaineBoost);
    
    % display high-boosted image
    figure;
    imshow(elaineBoost, []);
    title(['High-Boosted Image, CF=', num2str(cf)]);
end