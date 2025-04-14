%% Simplified TCN Lip Reading Model with Fixed Class Recognition
% This script is designed specifically to work with your dataset structure
% Authors: Kevin Zhang (400319666), Peter Kosir (400331918)
% COMPENG 4TN4 Image Processing

clear;
clc;
close all;

%% Configuration
wordClasses = {'Apple', 'Hello', 'Pen', 'Sulphur', 'Zebra'};
trainRatio = 0.8;  % Portion to use for training

%% Select Mode
fprintf('Select operation mode:\n');
fprintf('1. Extract and Visualize Features (Include All Samples)\n');
fprintf('2. Train Simple TCN Model\n');
fprintf('3. Live Recognition\n');
mode = input('Enter mode (1-3): ');

switch mode
    case 1
        % Extract features and visualize them
        [features, labels] = extractAndVisualize(wordClasses);
        save('lip_features.mat', 'features', 'labels');
        
    case 2
        % Load features if they exist, otherwise extract them
        if exist('lip_features.mat', 'file')
            load('lip_features.mat');
        else
            [features, labels] = extractAndVisualize(wordClasses);
        end
        [augFeatures, augLabels] = augmentLipData(features, labels, 5);
        % Train TCN model using your data
        [trainedModel, accuracy] = trainSimpleTCN(augFeatures, augLabels, wordClasses, trainRatio);
        save('trained_model.mat', 'trainedModel', 'accuracy', 'wordClasses');
        
    case 3
        % Live Recognition Mode
        if exist('trained_model.mat', 'file')
            load('trained_model.mat');
            % Add this line to use enhanced visualization (if file exists)
            if exist('lip_reading_visualizations.m', 'file')
                enhancedLiveRecognition(trainedModel, wordClasses);
            else
                % Fall back to original recognition
                startLiveRecognition(trainedModel, framesPerSample, frameStep);
            end
        else
            error('No trained model found. Please run training mode first.');
        end
        
    otherwise
        error('Invalid mode selected.');
end

%% Feature Extraction and Visualization Function
function [allFeatures, allLabels] = extractAndVisualize(wordClasses)
    % Get dataset directory
    fprintf('Select the directory containing your dataset\n');
    fprintf('This should contain subdirectories like framesApple, framesAppleBW, etc.\n');
    baseDir = uigetdir('', 'Select dataset directory');
    
    if baseDir == 0
        error('No directory selected.');
    end
    
    % Find all frame directories
    allDirs = dir(baseDir);
    dirNames = {allDirs([allDirs.isdir]).name};
    frameDirs = dirNames(startsWith(dirNames, 'frames'));
    frameDirs = setdiff(frameDirs, {'.', '..'});
    
    % Separate BW and original frame directories
    bwDirs = frameDirs(endsWith(frameDirs, 'BW'));
    origDirs = frameDirs(~endsWith(frameDirs, 'BW'));
    
    % Display found directories
    fprintf('Found %d directories:\n', length(frameDirs));
    fprintf('  BW directories: %d\n', length(bwDirs));
    fprintf('  Original directories: %d\n', length(origDirs));
    
    % Initialize feature and label arrays
    allFeatures = {};
    allLabelsStr = {};
    
    % Process each BW directory
    for i = 1:length(bwDirs)
        % Extract class name from directory name
        dirName = bwDirs{i};
        
        % Extract base class name (remove frames, BW, and any trailing numbers)
        % This is the key fix to recognize Apple2, Apple3, etc. as the same class
        rawClassName = regexprep(dirName, '^frames|BW$', '');
        className = regexprep(rawClassName, '\d+$', ''); % Remove trailing numbers
        
        % Skip if not in our list of classes
        if ~ismember(className, wordClasses)
            fprintf('Skipping unknown class: %s (from %s)\n', className, dirName);
            continue;
        end
        
        fprintf('Processing: %s (Class: %s)\n', dirName, className);
        
        % Define paths
        bwFrameDir = fullfile(baseDir, dirName);
        
        % Find corresponding original frame directory if it exists
        origDirName = strrep(dirName, 'BW', '');
        origFrameDir = fullfile(baseDir, origDirName);
        
        if ~exist(origFrameDir, 'dir')
            warning('Original frame directory not found: %s', origDirName);
            origFrameDir = '';
        end
        
        % Extract features
        try
            % Load BW frames
            bwFrames = dir(fullfile(bwFrameDir, '*.tif'));
            
            if isempty(bwFrames)
                warning('No frames found in %s', bwFrameDir);
                continue;
            end
            
            % Sort frames by name
            [~, order] = sort(str2double(regexprep({bwFrames.name}, '[^0-9]', '')));
            bwFrames = bwFrames(order);
            
            % Initialize feature arrays
            numFrames = length(bwFrames);
            
            % Time series features
            centroidX = zeros(numFrames, 1);
            centroidY = zeros(numFrames, 1);
            area = zeros(numFrames, 1);
            width = zeros(numFrames, 1);
            height = zeros(numFrames, 1);
            aspectRatio = zeros(numFrames, 1);
            
            % Process each frame
            validFrames = 0;
            figure('Name', ['Processing ' className], 'Position', [100, 100, 800, 600]);
            
            for j = 1:numFrames
                % Load BW frame
                bwPath = fullfile(bwFrameDir, bwFrames(j).name);
                bwImg = imread(bwPath);
                
                % Convert to binary if not already
                if ~islogical(bwImg)
                    bwImg = imbinarize(bwImg);
                end
                
                % Extract features
                stats = regionprops(bwImg, 'BoundingBox', 'Centroid', 'Area');
                
                % Skip if no regions found
                if isempty(stats)
                    continue;
                end
                
                % Find largest region
                if length(stats) > 1
                    areas = [stats.Area];
                    [~, idx] = max(areas);
                    stats = stats(idx);
                end
                
                % Get features
                validFrames = validFrames + 1;
                bbox = stats.BoundingBox;
                cent = stats.Centroid;
                
                % Store features
                centroidX(validFrames) = cent(1);
                centroidY(validFrames) = cent(2);
                area(validFrames) = stats.Area;
                width(validFrames) = bbox(3);
                height(validFrames) = bbox(4);
                aspectRatio(validFrames) = bbox(3) / max(bbox(4), 1);
                
                % Visualize every 10th frame
                if mod(j, 10) == 0 || j == 1 || j == numFrames
                    % Load original frame if available
                    if ~isempty(origFrameDir)
                        origPath = fullfile(origFrameDir, bwFrames(j).name);
                        if exist(origPath, 'file')
                            origImg = imread(origPath);
                            subplot(2, 2, 1);
                            imshow(origImg);
                            title(['Original Frame ' num2str(j)]);
                            
                            % Overlay bounding box
                            hold on;
                            rectangle('Position', bbox, 'EdgeColor', 'r', 'LineWidth', 2);
                            plot(cent(1), cent(2), 'g+', 'MarkerSize', 10);
                            hold off;
                        end
                    end
                    
                    % Show BW frame
                    subplot(2, 2, 2);
                    imshow(bwImg);
                    title(['BW Frame ' num2str(j)]);
                    
                    % Show centroid movement
                    subplot(2, 2, 3);
                    plot(centroidX(1:validFrames), centroidY(1:validFrames), 'b-o');
                    title('Centroid Movement');
                    xlabel('X Position');
                    ylabel('Y Position');
                    grid on;
                    
                    % Show lip area over time
                    subplot(2, 2, 4);
                    plot(1:validFrames, area(1:validFrames), 'r-');
                    title('Lip Area Over Time');
                    xlabel('Frame');
                    ylabel('Area (pixels)');
                    grid on;
                    
                    drawnow;
                    pause(0.05);
                end
            end
            
            % Trim arrays to valid frames
            centroidX = centroidX(1:validFrames);
            centroidY = centroidY(1:validFrames);
            area = area(1:validFrames);
            width = width(1:validFrames);
            height = height(1:validFrames);
            aspectRatio = aspectRatio(1:validFrames);
            
            % Create feature structure
            if validFrames >= 10
                featureStruct = struct();
                featureStruct.centroidX = centroidX;
                featureStruct.centroidY = centroidY;
                featureStruct.area = area;
                featureStruct.width = width;
                featureStruct.height = height;
                featureStruct.aspectRatio = aspectRatio;
                featureStruct.lipRatio = height ./ max(width, 1);
                
                % Add to dataset
                allFeatures{end+1} = featureStruct;
                allLabelsStr{end+1} = className;
                
                fprintf('Added sample for %s with %d frames (from %s)\n', className, validFrames, dirName);
            else
                warning('Not enough valid frames for %s (%d frames)', className, validFrames);
            end
            
            close gcf;
            
        catch e
            warning('Error processing %s: %s', dirName, e.message);
        end
    end
    
    % Convert labels to categorical
    allLabels = categorical(allLabelsStr);
    
    % Display summary
    fprintf('\nExtracted features from %d samples:\n', length(allFeatures));
    for i = 1:length(wordClasses)
        count = sum(allLabels == wordClasses{i});
        fprintf('  %s: %d samples\n', wordClasses{i}, count);
    end
    
    % Create summary visualization
    if ~isempty(allFeatures)
        visualizeFeatures(allFeatures, allLabels);
    end
end

%% Feature Visualization
function visualizeFeatures(features, labels)
    % Create visualization of features across classes
    classes = categories(labels);
    numClasses = length(classes);
    
    % Create figure
    figure('Name', 'Feature Comparison', 'Position', [100, 100, 1200, 800]);
    
    % Plot lip ratio across classes
    subplot(2, 2, 1);
    hold on;
    
    colors = lines(numClasses);
    
    for i = 1:numClasses
        classIdx = find(labels == classes{i});
        
        for j = 1:length(classIdx)
            % Get sample
            sample = features{classIdx(j)};
            
            % Calculate mean lip ratio
            meanLipRatio = mean(sample.lipRatio);
            
            % Plot as scatter point
            scatter(i, meanLipRatio, 100, colors(i,:), 'filled');
            
            % Add class name
            if j == 1
                text(i, meanLipRatio, ['  ' char(classes{i})], 'FontSize', 10);
            end
        end
    end
    
    title('Mean Lip Ratio by Class');
    xlabel('Class');
    ylabel('Mean Lip Ratio (Height/Width)');
    grid on;
    
    % Plot area variation
    subplot(2, 2, 2);
    hold on;
    
    for i = 1:numClasses
        classIdx = find(labels == classes{i});
        
        for j = 1:length(classIdx)
            % Get sample
            sample = features{classIdx(j)};
            
            % Calculate area variation
            areaVar = std(sample.area) / mean(sample.area);
            
            % Plot as scatter point
            scatter(i, areaVar, 100, colors(i,:), 'filled');
            
            % Add class name
            if j == 1
                text(i, areaVar, ['  ' char(classes{i})], 'FontSize', 10);
            end
        end
    end
    
    title('Lip Area Variation by Class');
    xlabel('Class');
    ylabel('Area Variation (Std/Mean)');
    grid on;
    
    % Plot centroid movement
    subplot(2, 2, 3);
    hold on;
    
    for i = 1:min(numClasses, 5)  % Limit to 5 classes for clarity
        classIdx = find(labels == classes{i});
        
        % Use first sample for each class
        if ~isempty(classIdx)
            sample = features{classIdx(1)};
            
            % Plot centroid path
            plot(sample.centroidX, sample.centroidY, 'LineWidth', 2, 'Color', colors(i,:));
            
            % Add class name
            text(sample.centroidX(1), sample.centroidY(1), ['  ' char(classes{i})], 'FontSize', 10);
        end
    end
    
    title('Centroid Movement (First Sample of Each Class)');
    xlabel('X Position');
    ylabel('Y Position');
    grid on;
    
    % Plot aspect ratio over time
    subplot(2, 2, 4);
    hold on;
    
    for i = 1:min(numClasses, 5)  % Limit to 5 classes for clarity
        classIdx = find(labels == classes{i});
        
        % Use first sample for each class
        if ~isempty(classIdx)
            sample = features{classIdx(1)};
            
            % Normalize time to 0-1 range
            normTime = linspace(0, 1, length(sample.aspectRatio));
            
            % Plot aspect ratio
            plot(normTime, sample.aspectRatio, 'LineWidth', 2, 'Color', colors(i,:));
        end
    end
    
    legend(classes(1:min(numClasses, 5)));
    title('Aspect Ratio Over Time (First Sample of Each Class)');
    xlabel('Normalized Time');
    ylabel('Aspect Ratio (Width/Height)');
    grid on;
end

%% TCN Model Training
function [trainedModel, accuracy] = trainSimpleTCN(features, labels, wordClasses, trainRatio)
    % Train a simplified TCN model on the extracted features
    fprintf('Training TCN model...\n');
    
    % Check if we have enough data
    if length(features) < 2
        error('Not enough samples to train a model. Need at least 2.');
    end
    
    % Split data into training and validation sets
    [trainFeatures, trainLabels, valFeatures, valLabels] = splitData(features, labels, trainRatio);
    
    fprintf('Training set: %d samples\n', length(trainFeatures));
    fprintf('Validation set: %d samples\n', length(valFeatures));
    
    % Create and train a simple TCN model
    trainedModel = trainSimpleClassifier(trainFeatures, trainLabels, valFeatures, valLabels, wordClasses);
    
    % Evaluate the model if it has proper predict functionality
    try
        % Evaluate on validation set one by one
        numCorrect = 0;
        
        % Display header for validation results
        fprintf('\nValidation Results:\n');
        fprintf('%-10s %-10s %-10s\n', 'Sample', 'Actual', 'Predicted');
        fprintf('----------------------------------------\n');
        
        % Process each validation sample
        for i = 1:length(valFeatures)
            % Get prediction for current sample
            pred = trainedModel.predict(valFeatures{i});
            
            % Convert to string for display
            if ischar(pred) || isstring(pred)
                predStr = char(pred);
            elseif iscategorical(pred)
                predStr = char(pred);
            else
                % Handle other types like numeric
                predStr = 'Unknown';
            end
            
            % Get actual label
            actualStr = char(valLabels(i));
            
            % Display result for this sample
            fprintf('%-10d %-10s %-10s', i, actualStr, predStr);
            
            % Check if correct
            if strcmp(predStr, actualStr)
                numCorrect = numCorrect + 1;
                fprintf(' ✓\n');
            else
                fprintf(' ✗\n');
            end
        end
        
        % Calculate and display accuracy
        accuracy = numCorrect / length(valLabels);
        fprintf('\nFinal validation accuracy: %.2f%% (%d/%d correct)\n', ...
            accuracy * 100, numCorrect, length(valLabels));
        
    catch evalErr
        warning('Could not evaluate model: %s', evalErr.message);
        fprintf('Error details: %s\n', getReport(evalErr));
        accuracy = 0;
    end
    
    % Save the model
    save('trained_model.mat', 'trainedModel', 'accuracy', 'wordClasses');
    fprintf('Model saved to trained_model.mat\n');
end

%% Data Splitting
function [trainFeatures, trainLabels, valFeatures, valLabels] = splitData(features, labels, trainRatio)
    % Split the data into training and validation sets
    classes = categories(labels);
    
    % Debug information
    fprintf('Original dataset: %d samples, %d classes\n', length(features), length(classes));
    
    trainIndices = []; % Changed to collect indices first
    valIndices = [];   % Changed to collect indices first
    
    % Split each class separately to maintain balance
    for i = 1:length(classes)
        classIdx = find(labels == classes{i});
        
        fprintf('Class %s: %d samples\n', char(classes{i}), length(classIdx));
        
        if isempty(classIdx)
            continue;
        end
        
        % Shuffle indices
        rng(42 + i);  % For reproducibility
        classIdx = classIdx(randperm(length(classIdx)));
        
        % Split
        numTrain = max(1, round(length(classIdx) * trainRatio));
        
        % Store indices instead of immediately assigning
        trainIndices = [trainIndices; classIdx(1:numTrain)];
        
        % Validation set
        if numTrain < length(classIdx)
            valIndices = [valIndices; classIdx(numTrain+1:end)];
        end
    end
    
    % Debug information
    fprintf('Training indices: %d, Validation indices: %d\n', length(trainIndices), length(valIndices));
    
    % Now use the collected indices to extract features and labels
    trainFeatures = features(trainIndices);
    trainLabels = labels(trainIndices);
    valFeatures = features(valIndices);
    valLabels = labels(valIndices);
    
    % Ensure labels are column vectors
    trainLabels = trainLabels(:);
    valLabels = valLabels(:);
    
    % Additional check to ensure feature count matches label count
    if length(trainFeatures) ~= length(trainLabels)
        warning('Mismatch after splitting: %d train features vs %d train labels', ...
            length(trainFeatures), length(trainLabels));
        
        % Use the smaller of the two
        minCount = min(length(trainFeatures), length(trainLabels));
        trainFeatures = trainFeatures(1:minCount);
        trainLabels = trainLabels(1:minCount);
    end
    
    if length(valFeatures) ~= length(valLabels)
        warning('Mismatch after splitting: %d val features vs %d val labels', ...
            length(valFeatures), length(valLabels));
        
        % Use the smaller of the two
        minCount = min(length(valFeatures), length(valLabels));
        valFeatures = valFeatures(1:minCount);
        valLabels = valLabels(1:minCount);
    end
end

%% Simple Classifier
function model = trainSimpleClassifier(trainFeatures, trainLabels, valFeatures, valLabels, wordClasses)
    % Create a simple classifier instead of a complex TCN
    % This function works with the small dataset you have
    
    % Extract features for classification
    numTrain = length(trainFeatures);
    numVal = length(valFeatures);
    
    % Debug information
    fprintf('Number of training samples: %d\n', numTrain);
    fprintf('Number of training labels: %d\n', length(trainLabels));
    
    % Ensure we have the same number of features and labels
    if numTrain ~= length(trainLabels)
        warning('Mismatch between features (%d) and labels (%d). Adjusting...', numTrain, length(trainLabels));
        % Use the minimum number to ensure they match
        minLen = min(numTrain, length(trainLabels));
        trainFeatures = trainFeatures(1:minLen);
        trainLabels = trainLabels(1:minLen);
        numTrain = minLen;
    end
    
    % Calculate summary features for each time series
    trainFeatMat = zeros(numTrain, 7);
    valFeatMat = zeros(numVal, 7);
    
    % Ensure trainLabels and valLabels are column vectors
    trainLabels = trainLabels(:);
    valLabels = valLabels(:);
    
    % Process training data
    validTrainCount = 0;
    for i = 1:numTrain
        sample = trainFeatures{i};
        
        try
            % Calculate summary statistics
            trainFeatMat(i, 1) = mean(sample.lipRatio);
            trainFeatMat(i, 2) = std(sample.lipRatio);
            trainFeatMat(i, 3) = mean(sample.area);
            trainFeatMat(i, 4) = std(sample.area) / mean(sample.area);
            trainFeatMat(i, 5) = std(sample.centroidX) + std(sample.centroidY);
            trainFeatMat(i, 6) = max(sample.lipRatio) - min(sample.lipRatio);
            trainFeatMat(i, 7) = max(sample.area) / min(sample.area);
            validTrainCount = validTrainCount + 1;
        catch e
            warning('Error processing training sample %d: %s', i, e.message);
        end
    end
    
    % Process validation data
    validValCount = 0;
    for i = 1:numVal
        sample = valFeatures{i};
        
        try
            % Calculate summary statistics
            valFeatMat(i, 1) = mean(sample.lipRatio);
            valFeatMat(i, 2) = std(sample.lipRatio);
            valFeatMat(i, 3) = mean(sample.area);
            valFeatMat(i, 4) = std(sample.area) / mean(sample.area);
            valFeatMat(i, 5) = std(sample.centroidX) + std(sample.centroidY);
            valFeatMat(i, 6) = max(sample.lipRatio) - min(sample.lipRatio);
            valFeatMat(i, 7) = max(sample.area) / min(sample.area);
            validValCount = validValCount + 1;
        catch e
            warning('Error processing validation sample %d: %s', i, e.message);
        end
    end
    
    % Trim to only valid entries if any errors occurred
    if validTrainCount < numTrain
        trainFeatMat = trainFeatMat(1:validTrainCount, :);
        trainLabels = trainLabels(1:validTrainCount);
    end
    
    if validValCount < numVal
        valFeatMat = valFeatMat(1:validValCount, :);
        valLabels = valLabels(1:validValCount);
    end
    
    % Display the labels for debugging
    fprintf('Final training data dimensions: %d samples x %d features\n', size(trainFeatMat, 1), size(trainFeatMat, 2));
    fprintf('Final training labels count: %d\n', length(trainLabels));
    
    % Display the labels for debugging
    fprintf('Training labels (class distribution):\n');
    tabulate(trainLabels);
    
    % Check for NaN or Inf values
    if any(isnan(trainFeatMat(:))) || any(isinf(trainFeatMat(:)))
        warning('Training data contains NaN or Inf values. Replacing with zeros.');
        trainFeatMat(isnan(trainFeatMat) | isinf(trainFeatMat)) = 0;
    end
    
    % Train a classification model using a decision tree (simple and robust)
    try
        fprintf('Attempting to train ensemble model...\n');
        modelObj = fitcensemble(trainFeatMat, trainLabels, 'Method', 'Bag', 'NumLearningCycles', 50);
        fprintf('Ensemble model trained successfully.\n');
        
        % Evaluate on validation set
        if ~isempty(valFeatMat)
            valPred = predict(modelObj, valFeatMat);
            accuracy = sum(valPred == valLabels) / length(valLabels);
            fprintf('Validation accuracy: %.2f%%\n', accuracy * 100);
        end
        
        % Create a wrapper structure
        model = struct();
        model.type = 'ensemble';
        model.modelObj = modelObj;
        model.predict = @(timeSeries) predictTimeSeriesWrapper(modelObj, timeSeries);
        
    catch e
        fprintf('Error during ensemble model training: %s\n', e.message);
        fprintf('Falling back to decision tree classifier\n');
        
        try
            % Fall back to a simpler model if ensemble fails
            modelObj = fitctree(trainFeatMat, trainLabels);
            fprintf('Decision tree model trained successfully.\n');
            
            % Create wrapper
            model = struct();
            model.type = 'tree';
            model.modelObj = modelObj;
            model.predict = @(timeSeries) predictTimeSeriesWrapper(modelObj, timeSeries);
            
        catch e2
            fprintf('Error during decision tree training: %s\n', e2.message);
            fprintf('Creating a dummy model with most frequent class\n');
            
            % If all else fails, create a dummy model that always predicts the most common class
            [counts, ~] = histcounts(trainLabels);
            [~, maxIdx] = max(counts);
            mostCommonClass = trainLabels(maxIdx);
            
            model = struct();
            model.type = 'dummy';
            model.mostCommonClass = mostCommonClass;
            model.predict = @(~) mostCommonClass;
        end
    end
end

function prediction = predictTimeSeriesWrapper(modelObj, timeSeries)
    % This is a wrapper function that handles feature extraction from time series data
    % and makes predictions using the trained model
    
    % Calculate the same summary features used in training
    features = zeros(1, 7);
    
    try
        features(1) = mean(timeSeries.lipRatio);
        features(2) = std(timeSeries.lipRatio);
        features(3) = mean(timeSeries.area);
        features(4) = std(timeSeries.area) / mean(timeSeries.area);
        features(5) = std(timeSeries.centroidX) + std(timeSeries.centroidY);
        features(6) = max(timeSeries.lipRatio) - min(timeSeries.lipRatio);
        features(7) = max(timeSeries.area) / min(timeSeries.area);
        
        % Check for NaN or Inf values
        if any(isnan(features)) || any(isinf(features))
            warning('Features contain NaN or Inf values. Replacing with zeros.');
            features(isnan(features) | isinf(features)) = 0;
        end
        
        % Make prediction using the trained model
        predResult = predict(modelObj, features);
        
        % Ensure the prediction is returned as a string
        if iscategorical(predResult)
            % Handle categorical arrays
            if ~isempty(predResult)
                prediction = char(predResult(1));
            else
                prediction = 'Unknown';
            end
        elseif ischar(predResult) || isstring(predResult)
            % Already a character or string
            prediction = char(predResult);
        elseif iscell(predResult)
            % Handle cell arrays
            if ~isempty(predResult) && (ischar(predResult{1}) || isstring(predResult{1}))
                prediction = char(predResult{1});
            else
                prediction = 'Unknown';
            end
        else
            % Handle other types (numeric, etc.)
            prediction = 'Unknown';
        end
        
    catch e
        warning('Error during prediction: %s', e.message);
        % Return a default prediction if there's an error
        prediction = 'Unknown';
    end
    
    % Debug output
    fprintf('Debug - Predicted: %s\n', prediction);
end

%% Prediction Function for Time Series
function prediction = predictTimeSeries(model, timeSeries, originalPredict)
    % We don't need this function anymore as we're now using the custom wrapper
    % function predictTimeSeriesWrapper in the trainSimpleClassifier
    error('This function should not be called directly.');
end

%% Live Recognition Function
function liveRecognition(model, wordClasses)
    % Function for live recognition using webcam
    
    % Initialize webcam
    try
        cam = webcam();
    catch e
        error('Could not initialize webcam: %s', e.message);
    end
    
    % Create GUI figure
    fig = figure('Name', 'Live Lip Reading', 'Position', [100, 100, 1000, 600]);
    
    % Create UI controls
    uicontrol('Style', 'pushbutton', 'String', 'Start Recording', ...
        'Position', [50, 30, 120, 30], 'Callback', @startRecording);
    
    uicontrol('Style', 'pushbutton', 'String', 'Stop/Recognize', ...
        'Position', [180, 30, 120, 30], 'Callback', @stopRecording);
    
    uicontrol('Style', 'pushbutton', 'String', 'Exit', ...
        'Position', [310, 30, 80, 30], 'Callback', @exitApp);
    
    % Display area for results
    resultText = uicontrol('Style', 'text', 'String', 'Press "Start Recording" to begin...', ...
        'Position', [400, 30, 400, 30], 'FontSize', 12, 'HorizontalAlignment', 'left');
    
    % Initialize variables
    isRecording = false;
    featureStruct = struct();
    featureStruct.centroidX = [];
    featureStruct.centroidY = [];
    featureStruct.area = [];
    featureStruct.width = [];
    featureStruct.height = [];
    featureStruct.aspectRatio = [];
    featureStruct.lipRatio = [];
    frameCount = 0;
    
    % Main loop
    while ishandle(fig)
        % Capture frame
        frame = snapshot(cam);
        
        % Process frame to extract lip region
        [lipMask, lipFeatures] = processFrame(frame);
        
        % Display original frame
        subplot(2, 2, 1);
        imshow(frame);
        title('Camera Feed');
        
        % If lip features were found, overlay them
        if ~isempty(lipFeatures) && lipFeatures.LipFound
            hold on;
            rectangle('Position', lipFeatures.BoundingBox, 'EdgeColor', 'r', 'LineWidth', 2);
            plot(lipFeatures.Centroid(1), lipFeatures.Centroid(2), 'g+', 'MarkerSize', 10);
            hold off;
            
            % Display lip mask
            subplot(2, 2, 2);
            imshow(lipMask);
            title('Detected Lip Region');
            
            % If recording, store features
            if isRecording
                frameCount = frameCount + 1;
                
                % Store features
                featureStruct.centroidX(frameCount) = lipFeatures.Centroid(1);
                featureStruct.centroidY(frameCount) = lipFeatures.Centroid(2);
                featureStruct.area(frameCount) = lipFeatures.Area;
                featureStruct.width(frameCount) = lipFeatures.BoundingBox(3);
                featureStruct.height(frameCount) = lipFeatures.BoundingBox(4);
                featureStruct.aspectRatio(frameCount) = lipFeatures.BoundingBox(3) / lipFeatures.BoundingBox(4);
                featureStruct.lipRatio(frameCount) = lipFeatures.BoundingBox(4) / lipFeatures.BoundingBox(3);
                
                % Update recording status
                set(resultText, 'String', sprintf('Recording... Frames: %d', frameCount));
                
                % Plot features
                if frameCount > 1
                    % Plot centroid movement
                    subplot(2, 2, 3);
                    plot(featureStruct.centroidX, featureStruct.centroidY, 'b-o');
                    title('Centroid Movement');
                    grid on;
                    
                    % Plot lip ratio
                    subplot(2, 2, 4);
                    plot(1:frameCount, featureStruct.lipRatio, 'r-');
                    title('Lip Ratio Over Time');
                    grid on;
                end
            end
        else
            % No lips detected
            subplot(2, 2, 2);
            imshow(zeros(size(frame, 1), size(frame, 2)));
            title('No Lips Detected');
            
            if isRecording
                set(resultText, 'String', 'Recording paused - No lips detected');
            end
        end
        
        drawnow;
        pause(0.05);
    end
    
    % Cleanup
    clear cam;
    
    % Nested callback functions
    function startRecording(~, ~)
        % Reset feature structure
        featureStruct = struct();
        featureStruct.centroidX = [];
        featureStruct.centroidY = [];
        featureStruct.area = [];
        featureStruct.width = [];
        featureStruct.height = [];
        featureStruct.aspectRatio = [];
        featureStruct.lipRatio = [];
        frameCount = 0;
        
        % Start recording
        isRecording = true;
        set(resultText, 'String', 'Recording started...');
    end
    
    function stopRecording(~, ~)
        % Stop recording
        isRecording = false;
        
        % Check if enough frames were recorded
        if frameCount < 10
            set(resultText, 'String', 'Not enough frames recorded. Try again.');
            return;
        end
        
        % Make prediction
        try
            % Use our custom predict method
            prediction = model.predict(featureStruct);
            set(resultText, 'String', sprintf('Recognized: %s', char(prediction)));
        catch e
            set(resultText, 'String', sprintf('Error in prediction: %s', e.message));
        end
    end
    
    function exitApp(~, ~)
        close(fig);
    end
end

%% Frame Processing Function
function [lipMask, lipFeatures] = processFrame(frame)
    % Process frame to extract lip region
    
    % Convert to YCbCr color space
    img = rgb2ycbcr(frame);
    [~, cb, cr] = imsplit(img);
    
    % Apply thresholds for lip detection (from original frame_extract.m)
    cb_thresh = cb < 114;
    cr_thresh = cr > 166;
    
    % Process mask
    cr_lim = bwareafilt(cr_thresh, 1);
    lips = cb_thresh & cr_lim;
    
    % Clean up mask
    lips = imclose(lips, strel('disk', 4));
    lipMask = imclose(lips, strel('disk', 10));
    
    % Extract features
    stats = regionprops(lipMask, 'BoundingBox', 'Centroid', 'Area');
    
    % Initialize result
    lipFeatures = struct('LipFound', false);
    
    % If lips found, extract features
    if ~isempty(stats)
        % Find largest region
        if length(stats) > 1
            areas = [stats.Area];
            [~, idx] = max(areas);
            stats = stats(idx);
        end
        
        % Extract features
        lipFeatures.LipFound = true;
        lipFeatures.BoundingBox = stats.BoundingBox;
        lipFeatures.Centroid = stats.Centroid;
        lipFeatures.Area = stats.Area;
    end
end