%MAIN CODE FOR ALL UTILITY. YOU HAVE TO PROCESS THE FRAMES WITHIN "test.m"
%BEFORE YOU CAN USE THIS 

clc;
clear;
close all;

%%%%%%%% NOTE %%%%%%%%
% To change which dataset you are using, change both the "frameDir" and
% "rawFrameDir" to the correct dataset. So for "apple", use "framesAppleBW"
% and "framesApple".

%%{
frameDir = 'framesSulphurBW';
frames = dir(fullfile(frameDir, '*.tif')); % gets all .tif files from our preprocessed frames
numFrames = length(frames);

% FOR VISUALIZATION ONLY
%-----------------------%
rawFrameDir = 'framesSulphur';
rawFrames = dir(fullfile(rawFrameDir, '*.tif'));
%-----------------------%

centSer = zeros(numFrames, 2); % stores X and Y position of the centroid
areaSer = zeros(numFrames, 1); % stores lip area
bboxWidth = zeros(numFrames, 1); % stores width of lip area 
bboxHeight = zeros(numFrames, 1); % stores height of lip area
aspectRatio = zeros(numFrames, 1); % stores width/height ratio of lip area (can indicate open mouth, pursed lips, etc)

for i = 1:numFrames 
    % loads each frame individually
    path = fullfile(frameDir, frames(i).name);
    img = imread(path);

    stats = regionprops(img, 'BoundingBox', 'Centroid', 'Area');

    % safeguard in case we have some weird behaviour
    if ~isempty(stats)
        bbox = stats.BoundingBox;  % extract bounding box
        centroid = stats.Centroid; % extract centroid
        area = stats.Area; % extract area
        
        % store time-series
        centSer(i, :) = centroid;
        areaSer(i) = area;
        bboxWidth(i) = bbox(3); 
        bboxHeight(i) = bbox(4);
        aspectRatio(i) = bboxWidth(i)/bboxHeight(i);
        
        % FOR VISUALIZATION ONLY
        %-----------------------%
        disp = mod(i, 5); %checks if we should display or not, want to display every 10th image
        if disp==0
           
            img = uint8(img) * 255; % convert to unint8 to avoid errors in insertShape
            imgBox = insertShape(img, 'Rectangle', bbox, 'Color', 'green', 'LineWidth', 2); % add bounding box
            imgBoxCent = insertShape(imgBox, 'Circle', [centroid 5], 'Color', 'blue', 'LineWidth', 2); % add centroid
            
            % imshow(imgBoxCent);
            figure('Position', [0, 0, 1920, 1080]); % opens images in fullscreen for easier viewing
            rawImg = imread(fullfile(rawFrameDir, rawFrames(i).name)); % loads the original frame to display side-by-side
            close; %closes the previous image
            imshowpair(rawImg, imgBoxCent, 'montage');

            title(['Frame: ', num2str(i)]);
            pause(0.5); % pause to visualize the process
        end
        %-----------------------%

    % prints the frame that causes the weird behaviour
    else
        fprintf('Frame %d FAILED TO DISPLAY', i);
        disp("FAIL");
    end
end

time = 1:numFrames;

% plot centroid movement over time
figure;
subplot(4,1,1);
plot(time, centSer(:,1), 'r', 'LineWidth', 2); hold on;
plot(time, centSer(:,2), 'b', 'LineWidth', 2);
xlabel('Frame Number');
ylabel('Centroid Position');
legend('X Position', 'Y Position');
title('Lip Movement Over Time');
grid on;

% plot lip area over time (NOTE: this differs from the area of the bounding box since both could help
subplot(4,1,2);
plot(time, areaSer, 'k', 'LineWidth', 2);
xlabel('Frame Number');
ylabel('Lip Area');
title('Lip Area Variation Over Time');
grid on;

% plot bounding box width & height over time
subplot(4,1,3);
plot(time, bboxWidth, 'g', 'LineWidth', 2); hold on;
plot(time, bboxHeight, 'm', 'LineWidth', 2);
xlabel('Frame Number');
ylabel('Bounding Box Size');
legend('Width', 'Height');
title('Lip Bounding Box Size Over Time');
grid on;

% plot aspect ratio over time
subplot(4,1,4);
plot(time, aspectRatio, 'k', 'LineWidth', 2);
xlabel('Frame Number');
ylabel('Aspect Ratio (Width/Height)');
title('Lip Aspect Ratio Over Time');
grid on;

%}

%{
orig_img = imread("frames\100.tif");

% remove small objects to avoid noise
bwImg = bwareaopen(orig_img, 50);

stats = regionprops(bwImg, 'BoundingBox', 'Centroid', 'Area');

if ~isempty(stats)
    % find largest connected component, should just be the lips
    % [~, idx] = max([stats.Area]); 
    % bbox = stats(idx).BoundingBox;  % extract bounding box
    % centroid = stats(idx).Centroid; % extract centroid

    bbox = stats.BoundingBox;  % extract bounding box
    centroid = stats.Centroid; % extract centroid
    
    img = uint8(orig_img) * 255; % convert to unint8 to avoid errors in insertShape
    
    
    % Overlay bounding box on the original image
    imgWithBox = insertShape(img, 'Rectangle', bbox, 'Color', 'green', 'LineWidth', 2);
    
    % Overlay centroid as a blue circle
    imgWithBox = insertShape(imgWithBox, 'Circle', [centroid 5], 'Color', 'blue', 'LineWidth', 2);
    
    % Show result
    imshow(imgWithBox);title('Lips with Bounding Box and Centroid');
end

%}