% Modified frame_extract.m script that creates directories automatically
% THIS SEPERATES THE VIDEO INTO FRAMES. THIS WAS DONE FOR BOTH THE ORIGINAL
% FRAMES OF THE VIDEO (FOR VISUALIZATION) AND FOR THE BINARIZED LIPS

% Clear workspace
clear;
clc;

% Change these parameters for each video you want to process
videoFile = 'dataset/zebra3.mp4';  % Change this to the video you want to process
originalFramesDir = 'framesZebra3';  % Change to match the video (original frames)
bwFramesDir = 'framesZebra3BW';  % Change to match the video (binary lip masks)

% Create directories if they don't exist
if ~exist(originalFramesDir, 'dir')
    mkdir(originalFramesDir);
    fprintf('Created directory: %s\n', originalFramesDir);
end

if ~exist(bwFramesDir, 'dir')
    mkdir(bwFramesDir);
    fprintf('Created directory: %s\n', bwFramesDir);
end

%pulled from: https://www.geeksforgeeks.org/how-to-extract-frames-from-a-video-in-matlab/

% import the video file 
obj = VideoReader(videoFile); 
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
    
    % Save original frame
    fullpath = fullfile(originalFramesDir, Strc);
    imwrite(Vid, fullpath);
    
    % Save BW lip mask
    fullpath = fullfile(bwFramesDir, Strc);
    imwrite(lips_clean, fullpath);
    
    % Display progress
    if mod(x, 10) == 0
        fprintf('Processed frame %d of %d\n', x, frames);
    end
end

fprintf('Processing complete! Extracted %d frames to %s and %s\n', frames, originalFramesDir, bwFramesDir);