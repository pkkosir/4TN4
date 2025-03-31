%THIS WAS ALL THE TESTING FOR HOW TO EXTRACT THE LIPS

clc;
clear;

orig_img = imread("framesSulphur\1.tif");
% orig_img = imread("frames\100.tif");

%{%
%---------------- TESTING AREA ----------------%
%----------------------------------------------%
%----------------------------------------------%


img = rgb2ycbcr(orig_img);
[y, cb, cr] = imsplit(img); %split into colour channels

%CAUSING TOO MANY PROBLEMS
% cb_eq = adapthisteq(cb);
% cr_eq = adapthisteq(cr);
% 
% bw = imbinarize(cr_eq, 'adaptive', 'Sensitivity', 0.57);
% lips1 = bwareafilt(bw, 1);
% % imshowpair(lips1,cr_eq, 'montage');


cb_thresh = cb < 114; 
cr_thresh = cr > 166;

cr_lim = bwareafilt(cr_thresh, 1);
lips2 = cb_thresh & cr_lim;

lips2 = imclose(lips2, strel('disk', 4)); % fill gaps in lips


% lips = lips1 & lips2;
lips_clean = imclose(lips2, strel('disk', 20)); % remove small noise, keeps imclose from overfilling


% imshowpair(lips, lips_clean, 'montage')

%%%%%%%%%% TEST %%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%

imgList = {orig_img, lips2, lips_clean};

figure;
montage(imgList);

%----------------------------------------------%
%----------------------------------------------%
%----------------------------------------------%
%}

%{
% THE CODE UNDER HERE WORKS FOR OUR TEST DATASET. NEED TO GET WORKING ON OUR THE REAL DATASET

img = rgb2ycbcr(orig_img);
[y, cb, cr] = imsplit(img); %split into colour channels

%NOTE: no noticable difference using all these changes
% cb_eq = adapthisteq(cb,'clipLimit',0.01,'Distribution','rayleigh','Alpha',0.4);
% cr_eq = adapthisteq(cr,'clipLimit',0.01,'Distribution','rayleigh','Alpha',0.4);
cb_eq = adapthisteq(cb);
cr_eq = adapthisteq(cr);

% found experimentally
cb_thresh = cb_eq > 120; 
cr_thresh = cr_eq > 130;


% imshowpair(cb_eq, cr_eq, 'montage');
imshowpair(cb_thresh, cr_thresh, 'montage');

mask = cb_thresh & cr_thresh;

lips = bwareafilt(mask, 1); %just the lips, but blown out

bw = imbinarize(cb_eq, 'adaptive', 'Sensitivity', 0.553); %necessary if not thresholding, determines minute differnce in lip pusring. experimentally found 

bw_clean = imopen(bw, strel('disk', 1)); % remove small noise, keeps imclose from overfilling
bw_clean = imclose(bw_clean, strel('disk', 5)); % fill gaps in lips
bw_clean = imfill(bw_clean, 'holes'); % fill small holes inside lips

bw_final = bwareafilt(bw, 3); 

comb = bw_clean & lips;

imgList = {cb_eq, cr_eq, img, mask, bw_clean, bw, lips, comb, orig_img};


figure;
montage(imgList);
%}