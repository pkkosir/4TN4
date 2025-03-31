% THIS SEPERATES THE VIDEO INTO FRAMES. THIS WAS DONE FOR BOTH THE ORIGINAL
% FRAMES OF THE VIDEO (FOR VISUALIZATION) AND FOR THE BINARIZED LIPS


%pulled from: https://www.geeksforgeeks.org/how-to-extract-frames-from-a-video-in-matlab/

% import the video file 
obj = VideoReader('dataset/zebra3.mp4'); 
vid = read(obj); 
  
 % read the total number of frames 
frames = obj.NumFrames; 
  
% file format of the frames to be saved in 
ST ='.tif'; 
  
% reading and writing the frames  
for x = 1 : frames 
  
    % converting integer to string 
    Sx = num2str(x); 
  
    % concatenating 2 strings 
    Strc = strcat(Sx, ST); 
    Vid = vid(:, :, :, x); 
    
    % EXTRACT THE LIP INFORMATION -pk
    img = rgb2ycbcr(Vid);
    [y, cb, cr] = imsplit(img); % split into colour channels

    cb_thresh = cb < 114; % experimentally determined
    cr_thresh = cr > 166;
    
    cr_lim = bwareafilt(cr_thresh, 1);
    lips2 = cb_thresh & cr_lim;
    
    lips2 = imclose(lips2, strel('disk', 4)); % fill gaps in lips
    
    lips_clean = imclose(lips2, strel('disk', 20)); 
    
    %{
    % EXTRACT THE LIP INFORMATION -pk
    img = rgb2ycbcr(Vid); %convert to YCbCr
    [y, cb, cr] = imsplit(img); %split into colour channels

    cb_eq = adapthisteq(cb); %equalize the relevant colour channels
    cr_eq = adapthisteq(cr);

    cb_thresh = cb_eq > 120; %only take values above threshold, experimentally determined
    cr_thresh = cr_eq > 130;

    mask = cb_thresh & cr_thresh; %combined subtractive mask, makes cleaner lines

    lips = bwareafilt(mask, 1); %just the lips, but blown out

    bw = imbinarize(cb_eq, 'adaptive', 'Sensitivity', 0.553); %necessary if not thresholding, determines minute differnce in lip pusring. experimentally found 

    %these can probably be optimized if we're having issues
    bw_clean = imopen(bw, strel('disk', 1)); % remove small noise, keeps imclose from overfilling
    bw_clean = imclose(bw_clean, strel('disk', 5)); % fill gaps in lips
    bw_clean = imfill(bw_clean, 'holes'); % fill small holes inside lips

    bw_final = bwareafilt(bw, 3); %due to image, need 3 largest features

    comb = bw_clean & lips; %combines blown out and more accurate lips
    %}

    cd framesZebraBW
  
    % exporting the frames 
    % imwrite(Vid, Strc);
    imwrite(lips_clean, Strc);
    cd ..   
end