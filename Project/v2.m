%% Lip Reading System - Complete Implementation
% This script contains all components of the lip reading system in one file
% Authors: Kevin Zhang (400319666), Peter Kosir (400331918)
% COMPENG 4TN4 Image Processing

%% Setup Environment
clear;
clc;
close all;

% Check required toolboxes
required_toolboxes = {'Image Processing Toolbox', 'Computer Vision Toolbox', ...
                     'Deep Learning Toolbox', 'Image Acquisition Toolbox'};
                     
installed = ver;
installed_toolboxes = {installed.Name};

missing_toolboxes = setdiff(required_toolboxes, installed_toolboxes);

if ~isempty(missing_toolboxes)
    warning('The following required toolboxes are not installed:');
    disp(missing_toolboxes);
else
    disp('All required toolboxes are installed.');
end

%% Configuration Parameters
% Words or phrases to recognize
wordClasses = {'Hello', 'Thank you', 'Yes', 'No', 'Please'};

% Data collection parameters
framesPerSample = 60;    % Number of frames to collect per sample
frameStep = 1;           % Process every nth frame (for speed)
numSamplesPerWord = 10;  % Number of samples to collect per word

% Training parameters
trainRatio = 0.8;        % Ratio of data to use for training

%% Select Mode
fprintf('Select operation mode:\n');
fprintf('1. Data Collection\n');
fprintf('2. Train Model\n');
fprintf('3. Live Recognition\n');
mode = input('Enter mode (1-3): ');

switch mode
    case 1
        % Data Collection Mode
        dataCollectionMode(wordClasses, numSamplesPerWord, framesPerSample, frameStep);
    case 2
        % Training Mode
        trainTestSplit('./data', trainRatio);
        [trainFeatures, trainLabels, validationFeatures, validationLabels] = loadDataset('./data');
        [net, info] = trainLipReadingModel(trainFeatures, trainLabels, validationFeatures, validationLabels);
        save('lip_reading_model.mat', 'net', 'info');
        evaluateModel(net, validationFeatures, validationLabels);
    case 3
        % Live Recognition Mode
        if exist('lip_reading_model.mat', 'file')
            load('lip_reading_model.mat');
            startLiveRecognition(net, framesPerSample, frameStep);
        else
            error('No trained model found. Please run training mode first.');
        end
    otherwise
        error('Invalid mode selected.');
end

%% Preprocessing Functions

function [lipMask, rgbFrame] = preprocessFrame(frame)
    % Detect face using Viola-Jones algorithm
    faceDetector = vision.CascadeObjectDetector();
    bbox = faceDetector(frame);
    
    if ~isempty(bbox)
        % Use the largest face if multiple faces are detected
        if size(bbox, 1) > 1
            areas = bbox(:,3) .* bbox(:,4);
            [~, idx] = max(areas);
            bbox = bbox(idx,:);
        end
        
        % Extract lower third of the face (mouth region)
        x = bbox(1);
        y = bbox(2) + 2*bbox(4)/3; % Start from lower third
        width = bbox(3);
        height = bbox(4)/3;
        
        % Check boundaries
        if y+height > size(frame,1)
            height = size(frame,1) - y;
        end
        
        % Extract the mouth region
        mouthRegion = frame(round(y):round(y+height), round(x):round(x+width), :);
        
        % Convert to YCbCr
        ycbcrMouth = rgb2ycbcr(mouthRegion);
        crChannel = ycbcrMouth(:,:,3);
        
        % Apply threshold
        threshold = graythresh(crChannel);
        lipMask = imbinarize(crChannel, threshold);
        
        % Apply morphological operations
        se = strel('disk', 3);
        lipMask = imclose(lipMask, se);
        lipMask = bwareaopen(lipMask, 30);
        
        % Create full-size mask
        fullMask = false(size(frame, 1), size(frame, 2));
        fullMask(round(y):round(y+height), round(x):round(x+width)) = lipMask;
        lipMask = fullMask;
    else
        % No face detected, use original method
        ycbcrFrame = rgb2ycbcr(frame);
        crChannel = ycbcrFrame(:,:,3);
        crChannelSmooth = imgaussfilt(crChannel, 1.5);
        threshold = graythresh(crChannelSmooth);
        binaryMask = imbinarize(crChannelSmooth, threshold);
        se1 = strel('disk', 5);
        closedMask = imclose(binaryMask, se1);
        lipMask = bwareaopen(closedMask, 100);
    end
    
    rgbFrame = frame;
end

function startVideoCapture(source)
    % This function handles video capture from webcam or file
    % source: 'webcam' or path to video file
    
    if strcmp(source, 'webcam')
        % Initialize webcam
        cam = webcam();
        videoSource = @() snapshot(cam);
        cleanup = @() clear('cam');
    else
        % Initialize video reader for file input
        vidReader = VideoReader(source);
        videoSource = @() readFrame(vidReader);
        cleanup = @() clear('vidReader');
    end
    
    % Create figure for display
    fig = figure('Name', 'Lip Motion Analysis', 'NumberTitle', 'off');
    
    % Process frames until figure is closed
    while ishandle(fig)
        try
            % Get frame from source
            frame = videoSource();
            
            % Preprocess frame to extract lip region
            [lipMask, rgbFrame] = preprocessFrame(frame);
            
            % Display results
            subplot(1, 2, 1); imshow(rgbFrame); title('Original Frame');
            subplot(1, 2, 2); imshow(lipMask); title('Detected Lip Region');
            
            drawnow;
        catch e
            if strcmp(e.identifier, 'MATLAB:VideoReader:EndOfFile')
                disp('End of video file reached.');
                break;
            else
                rethrow(e);
            end
        end
    end
    
    % Clean up resources
    cleanup();
end

%% Feature Extraction Functions

function features = extractLipFeatures(lipMask, rgbFrame)
    % This function extracts features from the lip region
    
    % Find connected components
    cc = bwconncomp(lipMask);
    
    % Compute properties of connected components
    props = regionprops(cc, 'Area', 'BoundingBox', 'Centroid', 'Perimeter', 'Eccentricity');
    
    % Sort regions by area (descending)
    [~, idx] = sort([props.Area], 'descend');
    
    % If no regions found, return empty features
    if isempty(idx)
        features = struct('LipFound', false);
        return;
    end
    
    % Take the largest region as the lip region
    lipRegion = props(idx(1));
    
    % Extract bounding box and convert to integers
    bbox = round(lipRegion.BoundingBox);
    
    % Extract additional features
    width = bbox(3);
    height = bbox(4);
    aspectRatio = width / height;
    centroid = lipRegion.Centroid;
    
    % Calculate lip height-to-width ratio
    lipRatio = height / width;
    
    % Extract the lip ROI from the original frame
    lipROI = imcrop(rgbFrame, bbox);
    
    % Create feature structure
    features = struct(...
        'LipFound', true, ...
        'BoundingBox', bbox, ...
        'Width', width, ...
        'Height', height, ...
        'AspectRatio', aspectRatio, ...
        'Centroid', centroid, ...
        'LipRatio', lipRatio, ...
        'ROI', lipROI, ...
        'Area', lipRegion.Area, ...
        'Perimeter', lipRegion.Perimeter, ...
        'Eccentricity', lipRegion.Eccentricity);
end

function timeSeriesFeatures = trackLipMovement(videoSource, numFrames, frameStep)
    % This function extracts lip features across multiple frames to create a time series
    % 
    % videoSource: 'webcam' or path to video file
    % numFrames: number of frames to process
    % frameStep: step size between frames (to control frame rate)
    
    % Initialize time series storage with empty arrays (not pre-allocated)
    timeSeriesFeatures = struct();
    timeSeriesFeatures.AspectRatio = [];
    timeSeriesFeatures.LipRatio = [];
    timeSeriesFeatures.Area = [];
    timeSeriesFeatures.Perimeter = [];
    timeSeriesFeatures.CentroidX = [];
    timeSeriesFeatures.CentroidY = [];
    timeSeriesFeatures.Width = [];
    timeSeriesFeatures.Height = [];
    timeSeriesFeatures.Eccentricity = [];
    timeSeriesFeatures.ROIs = {};
    
    % Setup video source
    if strcmp(videoSource, 'webcam')
        cam = webcam();
        getFrame = @() snapshot(cam);
        cleanup = @() clear('cam');
    else
        vidReader = VideoReader(videoSource);
        getFrame = @() readFrame(vidReader);
        cleanup = @() clear('vidReader');
    end
    
    % Process frames
    frameCount = 0;
    skippedFrames = 0;
    
    % Figure for visualization
    fig = figure('Name', 'Lip Tracking', 'NumberTitle', 'off', 'Position', [100, 100, 800, 600]);
    
    while frameCount < numFrames && ishandle(fig)
        try
            % Skip frames according to frameStep
            if skippedFrames < frameStep
                getFrame();
                skippedFrames = skippedFrames + 1;
                continue;
            end
            
            % Reset skipped frame counter
            skippedFrames = 0;
            
            % Get and process frame
            frame = getFrame();
            [lipMask, rgbFrame] = preprocessFrame(frame);
            features = extractLipFeatures(lipMask, rgbFrame);
            
            % Display current frame even if lips not detected
            subplot(2, 2, 1); 
            imshow(rgbFrame); 
            title('Original Frame');
            
            subplot(2, 2, 2); 
            imshow(lipMask); 
            title('Lip Mask');
            
            % If lips were detected, store features
            if features.LipFound
                frameCount = frameCount + 1;
                
                % Append features to time series using array concatenation
                timeSeriesFeatures.AspectRatio(frameCount) = features.AspectRatio;
                timeSeriesFeatures.LipRatio(frameCount) = features.LipRatio;
                timeSeriesFeatures.Area(frameCount) = features.Area;
                timeSeriesFeatures.Perimeter(frameCount) = features.Perimeter;
                timeSeriesFeatures.CentroidX(frameCount) = features.Centroid(1);
                timeSeriesFeatures.CentroidY(frameCount) = features.Centroid(2);
                timeSeriesFeatures.Width(frameCount) = features.Width;
                timeSeriesFeatures.Height(frameCount) = features.Height;
                timeSeriesFeatures.Eccentricity(frameCount) = features.Eccentricity;
                timeSeriesFeatures.ROIs{frameCount} = features.ROI;
                
                % Update display with lip detection
                subplot(2, 2, 1);
                imshow(rgbFrame);
                title('Original Frame');
                hold on;
                rectangle('Position', features.BoundingBox, 'EdgeColor', 'r', 'LineWidth', 2);
                plot(features.Centroid(1), features.Centroid(2), 'g+', 'MarkerSize', 10);
                hold off;
                
                % Plot some time series data
                if frameCount > 1
                    subplot(2, 2, 3);
                    plot(1:frameCount, timeSeriesFeatures.LipRatio(1:frameCount), 'b-');
                    title('Lip Ratio Time Series');
                    xlabel('Frame'); ylabel('Height/Width Ratio');
                    grid on;
                    
                    subplot(2, 2, 4);
                    plot(1:frameCount, timeSeriesFeatures.Area(1:frameCount), 'r-');
                    title('Lip Area Time Series');
                    xlabel('Frame'); ylabel('Area (pixels)');
                    grid on;
                end
                
                % Display progress
                fprintf('Processed frame %d of %d\n', frameCount, numFrames);
            else
                % If no lips detected, show a message
                subplot(2, 2, 3);
                text(0.5, 0.5, 'No lips detected. Position your face better.', 'HorizontalAlignment', 'center');
                axis([0 1 0 1]);
                axis off;
            end
            
            % Force display update
            drawnow;
            
        catch e
            if strcmp(e.identifier, 'MATLAB:VideoReader:EndOfFile')
                disp('End of video file reached.');
                break;
            else
                rethrow(e);
            end
        end
    end
    
    % Clean up resources
    cleanup();
    
    % If no frames were processed, return empty
    if frameCount == 0
        timeSeriesFeatures = [];
    end
end

%% Classification Functions

function [net, info] = trainLipReadingModel(trainFeatures, trainLabels, validationFeatures, validationLabels)
    % This function trains a Temporal Convolutional Network (TCN) for lip reading
    %
    % trainFeatures: Cell array of feature time series, each cell containing a
    %                structure with time series data for one sample
    % trainLabels: Categorical array of labels for training data
    % validationFeatures: Cell array of feature time series for validation
    % validationLabels: Categorical array of labels for validation data
    
    % Extract dimensions
    numSamples = length(trainFeatures);
    if numSamples == 0
        error('No training samples provided');
    end
    
    % Get sequence length (number of frames)
    seqLengths = cellfun(@(x) length(x.AspectRatio), trainFeatures);
    maxSeqLength = max(seqLengths);
    
    % Select features to use
    featureNames = {'AspectRatio', 'LipRatio', 'Area', 'Perimeter', ...
                   'CentroidX', 'CentroidY', 'Width', 'Height', 'Eccentricity'};
    numFeatures = length(featureNames);
    
    % Prepare training data
    X = zeros(maxSeqLength, numFeatures, 1, numSamples);
    
    % Convert each time series to a 3D array
    for i = 1:numSamples
        % Get current sample's features
        sample = trainFeatures{i};
        
        % Get actual sequence length for this sample
        seqLen = seqLengths(i);
        
        % Extract and normalize features
        for j = 1:numFeatures
            featureName = featureNames{j};
            featureData = sample.(featureName);
            
            % Normalize feature to [0, 1] range
            featureData = (featureData - min(featureData)) / (max(featureData) - min(featureData) + eps);
            
            % Store in X
            X(1:seqLen, j, 1, i) = featureData;
        end
    end
    
    % Define the TCN architecture
    numClasses = length(categories(trainLabels));
    
    layers = [
        sequenceInputLayer(numFeatures)
        
        convolution1dLayer(3, 64, 'Padding', 'causal')
        batchNormalizationLayer
        reluLayer
        
        convolution1dLayer(3, 64, 'Padding', 'causal', 'Dilation', 2)
        batchNormalizationLayer
        reluLayer
        
        convolution1dLayer(3, 128, 'Padding', 'causal', 'Dilation', 4)
        batchNormalizationLayer
        reluLayer
        
        globalAveragePooling1dLayer
        fullyConnectedLayer(numClasses)
        softmaxLayer
        classificationLayer
    ];
    
    % Define training options
    options = trainingOptions('adam', ...
        'MaxEpochs', 50, ...
        'MiniBatchSize', 16, ...
        'InitialLearnRate', 0.001, ...
        'GradientThreshold', 1, ...
        'Plots', 'training-progress', ...
        'Verbose', false, ...
        'ValidationData', {validationFeatures, validationLabels}, ...
        'ValidationFrequency', 10, ...
        'ValidationPatience', 5);
    
    % Train the network
    [net, info] = trainNetwork(X, trainLabels, layers, options);
end

function predictedLabel = classifyLipMovement(net, features)
    % This function classifies lip movement using the trained network
    %
    % net: Trained TCN network
    % features: Structure containing time series features
    
    % Select features used during training
    featureNames = {'AspectRatio', 'LipRatio', 'Area', 'Perimeter', ...
                   'CentroidX', 'CentroidY', 'Width', 'Height', 'Eccentricity'};
    numFeatures = length(featureNames);
    
    % Get sequence length
    seqLen = length(features.AspectRatio);
    
    % Prepare input data
    X = zeros(seqLen, numFeatures, 1, 1);
    
    % Extract and normalize features
    for j = 1:numFeatures
        featureName = featureNames{j};
        featureData = features.(featureName);
        
        % Normalize feature to [0, 1] range
        featureData = (featureData - min(featureData)) / (max(featureData) - min(featureData) + eps);
        
        % Store in X
        X(1:seqLen, j, 1, 1) = featureData;
    end
    
    % Classify the sequence
    predictedLabel = classify(net, X);
end

function trainTestSplit(dataDir, trainRatio)
    % This function splits video files into training and testing sets
    % 
    % dataDir: Directory containing class subdirectories with video files
    % trainRatio: Ratio of data to use for training (0-1)
    
    % Get list of class directories
    classDirs = dir(dataDir);
    classDirs = classDirs([classDirs.isdir]);
    classDirs = classDirs(~ismember({classDirs.name}, {'.', '..', 'train', 'test'}));
    
    % Create output directory structure
    trainDir = fullfile(dataDir, 'train');
    testDir = fullfile(dataDir, 'test');
    
    if ~exist(trainDir, 'dir')
        mkdir(trainDir);
    end
    
    if ~exist(testDir, 'dir')
        mkdir(testDir);
    end
    
    % Process each class
    for i = 1:length(classDirs)
        className = classDirs(i).name;
        classPath = fullfile(dataDir, className);
        
        % Create class directories in train and test
        trainClassDir = fullfile(trainDir, className);
        testClassDir = fullfile(testDir, className);
        
        if ~exist(trainClassDir, 'dir')
            mkdir(trainClassDir);
        end
        
        if ~exist(testClassDir, 'dir')
            mkdir(testClassDir);
        end
        
        % Get all video files
        videoFiles = dir(fullfile(classPath, '*.mp4'));
        videoFiles = [videoFiles; dir(fullfile(classPath, '*.avi'))];
        videoFiles = [videoFiles; dir(fullfile(classPath, '*.mov'))];
        
        % Also include .mat files
        matFiles = dir(fullfile(classPath, '*.mat'));
        allFiles = [videoFiles; matFiles];
        
        % Skip if no files found
        if isempty(allFiles)
            continue;
        end
        
        % Shuffle files
        rng(42); % For reproducibility
        allFiles = allFiles(randperm(length(allFiles)));
        
        % Split into train and test
        numTrain = round(length(allFiles) * trainRatio);
        
        for j = 1:length(allFiles)
            fileName = allFiles(j).name;
            filePath = fullfile(classPath, fileName);
            
            if j <= numTrain
                % Copy to train directory
                copyfile(filePath, fullfile(trainClassDir, fileName));
            else
                % Copy to test directory
                copyfile(filePath, fullfile(testClassDir, fileName));
            end
        end
        
        fprintf('Processed class %s: %d training samples, %d test samples\n', ...
            className, numTrain, length(allFiles) - numTrain);
    end
end

%% Application Functions

function dataCollectionMode(wordClasses, numSamplesPerWord, framesPerSample, frameStep)
    % This function collects lip movement data for training
    
    % Create data directory if it doesn't exist
    dataDir = './data';
    if ~exist(dataDir, 'dir')
        mkdir(dataDir);
    end
    
    % Create class directories
    for i = 1:length(wordClasses)
        classDir = fullfile(dataDir, wordClasses{i});
        if ~exist(classDir, 'dir')
            mkdir(classDir);
        end
    end
    
    % Initialize webcam
    cam = webcam();
    
    % Loop through classes
    for classIdx = 1:length(wordClasses)
        className = wordClasses{classIdx};
        classDir = fullfile(dataDir, className);
        
        % Collect multiple samples for each class
        for sampleIdx = 1:numSamplesPerWord
            % Define output file
            outputFile = fullfile(classDir, sprintf('%s_sample%d.mat', className, sampleIdx));
            
            % Check if sample already exists
            if exist(outputFile, 'file')
                fprintf('Sample %d for class %s already exists. Skipping...\n', sampleIdx, className);
                continue;
            end
            
            % Prompt user to prepare for recording
            f = figure('Name', sprintf('Recording: %s (Sample %d/%d)', className, sampleIdx, numSamplesPerWord), ...
                      'NumberTitle', 'off', 'Position', [100, 100, 400, 200]);
            
            % Start showing webcam feed while waiting
            subplot(1, 2, 1);
            h_img = imshow(snapshot(cam));
            title('Camera Preview');
            
            subplot(1, 2, 2);
            uicontrol('Style', 'text', ...
                     'String', sprintf('Prepare to say: "%s"\nPress any key to start recording...', className), ...
                     'Position', [210, 50, 180, 60]);
            
            % Update camera feed until keypress
            while ~waitforbuttonpress
                set(h_img, 'CData', snapshot(cam));
                drawnow;
                pause(0.05);
            end
            
            % Countdown
            for i = 3:-1:1
                clf;
                subplot(1, 2, 1);
                h_img = imshow(snapshot(cam));
                title('Camera Preview');
                
                subplot(1, 2, 2);
                uicontrol('Style', 'text', ...
                         'String', sprintf('Starting in %d...', i), ...
                         'Position', [210, 50, 180, 50]);
                drawnow;
                
                % Continuously update camera feed during countdown
                tStart = tic;
                while toc(tStart) < 1
                    set(h_img, 'CData', snapshot(cam));
                    drawnow;
                    pause(0.05);
                end
            end
            
            % Start recording
            close(f);
            
            % Record the sample
            videoSource = 'webcam';
            timeSeriesFeatures = trackLipMovement(videoSource, framesPerSample, frameStep);
            
            % Save the sample
            if ~isempty(timeSeriesFeatures)
                save(outputFile, 'timeSeriesFeatures', 'className');
                fprintf('Saved sample %d for class %s\n', sampleIdx, className);
            else
                warning('Failed to record sample %d for class %s. No lips detected.', sampleIdx, className);
            end
            
            % Short break between samples
            pause(1);
        end
    end
    
    % Clean up
    clear cam;
end

function [trainFeatures, trainLabels, validationFeatures, validationLabels] = loadDataset(dataDir)
    % This function loads the dataset from the specified directory
    
    % Get training and validation directories
    trainDir = fullfile(dataDir, 'train');
    validationDir = fullfile(dataDir, 'test');
    
    % Load training data
    trainFeatures = {};
    trainLabelsStr = {};
    
    % Get all class directories in training set
    classDirs = dir(trainDir);
    classDirs = classDirs([classDirs.isdir]);
    classDirs = classDirs(~ismember({classDirs.name}, {'.', '..'}));
    
    % Load each class
    for i = 1:length(classDirs)
        className = classDirs(i).name;
        classPath = fullfile(trainDir, className);
        
        % Get all sample files
        sampleFiles = dir(fullfile(classPath, '*.mat'));
        
        % Load each sample
        for j = 1:length(sampleFiles)
            filePath = fullfile(classPath, sampleFiles(j).name);
            data = load(filePath);
            
            % Add to training data
            trainFeatures{end+1} = data.timeSeriesFeatures;
            trainLabelsStr{end+1} = className;
        end
    end
    
    % Convert labels to categorical
    trainLabels = categorical(trainLabelsStr);
    
    % Load validation data
    validationFeatures = {};
    validationLabelsStr = {};
    
    % Get all class directories in validation set
    classDirs = dir(validationDir);
    classDirs = classDirs([classDirs.isdir]);
    classDirs = classDirs(~ismember({classDirs.name}, {'.', '..'}));
    
    % Load each class
    for i = 1:length(classDirs)
        className = classDirs(i).name;
        classPath = fullfile(validationDir, className);
        
        % Get all sample files
        sampleFiles = dir(fullfile(classPath, '*.mat'));
        
        % Load each sample
        for j = 1:length(sampleFiles)
            filePath = fullfile(classPath, sampleFiles(j).name);
            data = load(filePath);
            
            % Add to validation data
            validationFeatures{end+1} = data.timeSeriesFeatures;
            validationLabelsStr{end+1} = className;
        end
    end
    
    % Convert labels to categorical
    validationLabels = categorical(validationLabelsStr);
end

function evaluateModel(net, testFeatures, testLabels)
    % This function evaluates the trained model on test data
    
    % Initialize counters
    numCorrect = 0;
    numTotal = length(testFeatures);
    predictions = categorical(zeros(numTotal, 1));
    
    % Classify each test sample
    for i = 1:numTotal
        predictions(i) = classifyLipMovement(net, testFeatures{i});
        
        if predictions(i) == testLabels(i)
            numCorrect = numCorrect + 1;
        end
    end
    
    % Calculate accuracy
    accuracy = numCorrect / numTotal;
    
    % Display results
    fprintf('Model Evaluation:\n');
    fprintf('Total samples: %d\n', numTotal);
    fprintf('Correct predictions: %d\n', numCorrect);
    fprintf('Accuracy: %.2f%%\n', accuracy * 100);
    
    % Create confusion matrix
    figure('Name', 'Confusion Matrix', 'NumberTitle', 'off');
    cm = confusionchart(testLabels, predictions);
    cm.Title = 'Confusion Matrix';
    cm.RowSummary = 'row-normalized';
    cm.ColumnSummary = 'column-normalized';
end

function startLiveRecognition(net, framesPerSample, frameStep)
    % This function performs live lip reading using the trained model
    
    % Initialize webcam
    cam = webcam();
    
    % Create figure for display
    fig = figure('Name', 'Live Lip Reading', 'NumberTitle', 'off', 'Position', [100, 100, 800, 600]);
    
    % Create UI elements
    uicontrol('Style', 'pushbutton', ...
             'String', 'Start Reading', ...
             'Position', [50, 20, 100, 30], ...
             'Callback', @startReading);
    
    uicontrol('Style', 'pushbutton', ...
             'String', 'Exit', ...
             'Position', [200, 20, 100, 30], ...
             'Callback', @exitApp);
    
    resultText = uicontrol('Style', 'text', ...
                          'String', 'Press "Start Reading" to begin...', ...
                          'Position', [350, 20, 250, 30], ...
                          'HorizontalAlignment', 'left');
    
    % Initialize variables
    isRecording = false;
    timeSeriesFeatures = struct();
    timeSeriesFeatures.AspectRatio = [];
    timeSeriesFeatures.LipRatio = [];
    timeSeriesFeatures.Area = [];
    timeSeriesFeatures.Perimeter = [];
    timeSeriesFeatures.CentroidX = [];
    timeSeriesFeatures.CentroidY = [];
    timeSeriesFeatures.Width = [];
    timeSeriesFeatures.Height = [];
    timeSeriesFeatures.Eccentricity = [];
    timeSeriesFeatures.ROIs = {};
    frameCount = 0;
    
    % Main loop
    while ishandle(fig)
        % Capture frame
        frame = snapshot(cam);
        
        % Process frame
        [lipMask, rgbFrame] = preprocessFrame(frame);
        
        % Display frame
        subplot(2, 1, 1);
        imshow(rgbFrame);
        title('Live Camera Feed');
        
        % Extract features
        features = extractLipFeatures(lipMask, rgbFrame);
        
        % Display lip detection if found
        if features.LipFound
            hold on;
            rectangle('Position', features.BoundingBox, 'EdgeColor', 'r', 'LineWidth', 2);
            plot(features.Centroid(1), features.Centroid(2), 'g+', 'MarkerSize', 10);
            hold off;
        end
        
        % Extract features if recording
        if isRecording && features.LipFound
            % Increment frame counter
            frameCount = frameCount + 1;
            
            % Add features to time series
            timeSeriesFeatures.AspectRatio(frameCount) = features.AspectRatio;
            timeSeriesFeatures.LipRatio(frameCount) = features.LipRatio;
            timeSeriesFeatures.Area(frameCount) = features.Area;
            timeSeriesFeatures.Perimeter(frameCount) = features.Perimeter;
            timeSeriesFeatures.CentroidX(frameCount) = features.Centroid(1);
            timeSeriesFeatures.CentroidY(frameCount) = features.Centroid(2);
            timeSeriesFeatures.Width(frameCount) = features.Width;
            timeSeriesFeatures.Height(frameCount) = features.Height;
            timeSeriesFeatures.Eccentricity(frameCount) = features.Eccentricity;
            timeSeriesFeatures.ROIs{frameCount} = features.ROI;
            
            % Check if enough frames have been collected
            if frameCount >= framesPerSample
                % Stop recording
                isRecording = false;
                
                % Classify the sequence
                predictedLabel = classifyLipMovement(net, timeSeriesFeatures);
                
                % Display result
                set(resultText, 'String', sprintf('Recognized: %s', char(predictedLabel)));
                
                % Reset for next recording
                timeSeriesFeatures = struct();
                timeSeriesFeatures.AspectRatio = [];
                timeSeriesFeatures.LipRatio = [];
                timeSeriesFeatures.Area = [];
                timeSeriesFeatures.Perimeter = [];
                timeSeriesFeatures.CentroidX = [];
                timeSeriesFeatures.CentroidY = [];
                timeSeriesFeatures.Width = [];
                timeSeriesFeatures.Height = [];
                timeSeriesFeatures.Eccentricity = [];
                timeSeriesFeatures.ROIs = {};
                frameCount = 0;
            else
                % Update progress
                set(resultText, 'String', sprintf('Recording: %d/%d frames', frameCount, framesPerSample));
            end
        elseif isRecording && ~features.LipFound
            % Warning if recording but no lips detected
            set(resultText, 'String', 'Recording paused: No lips detected!');
        end
        
        % Display lip mask
        subplot(2, 1, 2);
        imshow(lipMask);
        title('Detected Lip Region');
        
        drawnow;
    end
    
    % Clean up
    clear cam;
    
    % Nested callback function for start button
    function startReading(~, ~)
        if ~isRecording
            % Reset variables
            timeSeriesFeatures = struct();
            timeSeriesFeatures.AspectRatio = [];
            timeSeriesFeatures.LipRatio = [];
            timeSeriesFeatures.Area = [];
            timeSeriesFeatures.Perimeter = [];
            timeSeriesFeatures.CentroidX = [];
            timeSeriesFeatures.CentroidY = [];
            timeSeriesFeatures.Width = [];
            timeSeriesFeatures.Height = [];
            timeSeriesFeatures.Eccentricity = [];
            timeSeriesFeatures.ROIs = {};
            frameCount = 0;
            
            % Start recording
            isRecording = true;
            set(resultText, 'String', 'Recording lip movements...');
        end
    end
    
    % Nested callback function for exit button
    function exitApp(~, ~)
        close(fig);
    end
end