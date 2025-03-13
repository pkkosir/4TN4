clc;
clear;

% orig_img = imread("origFrames\1.tif");
orig_img = imread("frames\1.tif");


%{
img = rgb2ycbcr(orig_img);
[y, cb, cr] = imsplit(img); %split into colour channels

%---------------- TESTING AREA ----------------%
%----------------------------------------------%
%----------------------------------------------%

% Cr components
cr_norm = imadjust(cr);
cr_boost = imadjust(cr_norm, [], [], 3);

%Cb components
cb_norm = imadjust(cb);
cb_boost = imadjust(cb_norm, [], [], 3);


cb_thresh = cb_boost > 100; 
cr_thresh = cr_boost > 100;

imgList = {cr, cr_norm, cr_boost, cb, cb_norm, cb_boost, cb_thresh, cr_thresh};

%----------------------------------------------%
%----------------------------------------------%
%----------------------------------------------%
%}
%{
%NOTE: no noticable difference using all these changes
% cb_eq = adapthisteq(cb,'clipLimit',0.01,'Distribution','rayleigh','Alpha',0.4);
% cr_eq = adapthisteq(cr,'clipLimit',0.01,'Distribution','rayleigh','Alpha',0.4);
cb_eq = adapthisteq(cb);
cr_eq = adapthisteq(cr);

% found experimentally
cb_thresh = cb_eq > 120; 
cr_thresh = cr_eq > 130;

% imshowpair(cb_eq, cr_eq, 'montage');
% imshowpair(cb_thresh, cr_thresh, 'montage');

mask = cb_thresh & cr_thresh;

lips = bwareafilt(mask, 1); %just the lips, but blown out

bw = imbinarize(cb_eq, 'adaptive', 'Sensitivity', 0.553); %necessary if not thresholding, determines minute differnce in lip pusring. experimentally found 

bw_clean = imopen(bw, strel('disk', 1)); % remove small noise, keeps imclose from overfilling
bw_clean = imclose(bw_clean, strel('disk', 5)); % fill gaps in lips
bw_clean = imfill(bw_clean, 'holes'); % fill small holes inside lips

bw_final = bwareafilt(bw, 3); 

comb = bw_clean & lips;

imgList = {cb_eq, cr_eq, img, mask, bw_clean, bw, lips, comb, orig_img};
%}

figure;
montage(imgList)
