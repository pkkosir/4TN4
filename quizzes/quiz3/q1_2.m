clear;
clc;
circuit = imread('circuit.tif'); 

% convert to black and white, originally has RGB and alpha. same image after
circuit = circuit(:, :, 1:3);
circuit = rgb2gray(circuit);
% imshow(circuit);

% structuring elements
se5 = ones(5,5);
se9 = ones(9,9);

% erosion
erode5 = erode(circuit, [5 5]);
erode9 = erode(circuit, [9 9]);

% dilation
dilate5 = dilate(circuit, [5 5]);
dilate9 = dilate(circuit, [9 9]);

% QUESTION 2 %
% opening aka dilation of erorded image
open5 = dilate(erode5, [5 5]); 
%%%%%%%%%%%%%%

% Display results
figure('Position', [50, 50, 900, 900]);
subplot(2,3,1), imshow(circuit), title('Original Circuit');
subplot(2,3,2), imshow(erode5), title('Eroded 5x5');
subplot(2,3,3), imshow(erode9), title('Eroded 9x9');
subplot(2,3,4), imshow(open5), title('Opened 5x5');
subplot(2,3,5), imshow(dilate5), title('Dilated 5x5');
subplot(2,3,6), imshow(dilate9), title('Dilated 9x9');


%}

function erodedImg = erode(img, size)
    padding = floor(size/2); % adds padding that is 2 for the 5x5 and 3 for the 7x7 to ensure proper kernel usage
    padImg = padarray(img, padding, Inf, 'both'); % pads infinity for erode, since erosion is a min filter
    filtImg = nlfilter(padImg, size, @(x) min(x(:))); % sliding MxN window filter, over padded image, finding the darkest pixesl in neighbourhood and setting that value to center pixel 
    erodedImg = filtImg(1+padding(1) : end-padding(1), 1+padding(2) : end-padding(2)); %removes the padding
end

function dilatedImg = dilate(img, size)
    padding = floor(size/2); % adds padding that is 2 for the 5x5 and 3 for the 7x7 to ensure proper kernel usage
    padImg = padarray(img, padding, -Inf, 'both'); % pads negative inf for dilate, since erosion is a max filter
    filtImg = nlfilter(padImg, size, @(x) max(x(:))); % sliding MxN window filter, over padded image, finding the lightest pixesl in neighbourhood and setting that value to center pixel 
    dilatedImg = filtImg(1+padding(1) : end-padding(1), 1+padding(2) : end-padding(2)); %removes padding
end