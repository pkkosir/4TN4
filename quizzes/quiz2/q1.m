clear;
clc;

einstein = imread('einstein.tif');
cman = imread('cman.tif');

BIT = 3; %bit to be changed

binCman = imbinarize(cman);
% imshowpair(cman, binCman, "montage");

bitPlanes = cell(1, 8);

for i = 1:8  % 1 reps LSB while 8 reps MSB
    bitPlanes{i} = bitget(einstein, i);
end  

bitPlanes{BIT} = binCman; %replaces the LSB with the binarized cameraman image


modEin = zeros(size(einstein), 'uint8'); %inital modified einstein file
for i = 1:8
    %element-wise addition of the bitplane values, multiplied by 2^(i-1) to represent the signficance of each bitplane
    modEin = modEin + uint8(bitPlanes{i}.*2.^(i-1)); 
end

% out = sum(einstein, "all")-sum(modEin, "all") %checks that the editing does something
imshowpair(einstein, modEin, "montage"); %displays orignal vs modified einstein images

qFactors = [100, 95, 90, 50]; %basically a percentage

% %{
for i=1:length(qFactors)
    imwrite(double(modEin)/255, 'temp.jpg', 'jpg', 'Quality', qFactors(i)); %compresses the image
    decomp = imread('temp.jpg'); %decompresses the image

    hidden = bitget(decomp, BIT); %gets the hidden cameraman image after decompression
    
    pixDiff = sum(hidden(:) ~= uint8(binCman(:)));
    
    figure('Position', [0 0 1920 1080]);
    subplot(1,3,1); imshow(decomp); 
    title('Decompressed Einstein');

    subplot(1,3,2); imshow(binCman); 
    title('Binarized Cameraman');

    subplot(1,3,3); imshow(hidden*255); 
    title(['Hidden, QF=', num2str(qFactors(i)), '; Diff: ', num2str(pixDiff), ' pixels' ]);

end
%}