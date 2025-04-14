function simulationDemo(model, wordClasses)
    % SIMULATION DEMO - Impressive visualization for lip reading project
    % Uses pre-trained model and validation data to simulate the lip reading process
    % with engaging animations and visualizations
    
    % Load the trained model and validation data
    if nargin < 1 || isempty(model)
        if exist('trained_model.mat', 'file')
            fprintf('Loading trained model...\n');
            load('trained_model.mat');
            model = trainedModel;
        else
            error('No model provided and no trained_model.mat found.');
        end
    end
    
    if nargin < 2 || isempty(wordClasses)
        wordClasses = {'Apple', 'Hello', 'Pen', 'Sulphur', 'Zebra'};
    end
    
    % Load validation data
    if exist('lip_features.mat', 'file')
        fprintf('Loading features data...\n');
        load('lip_features.mat');
        
        % Extract validation set (20% of data or at least 1 sample per class)
        [testFeatures, testLabels] = extractValidationSet(features, labels, 0.2);
    else
        error('Could not find lip_features.mat. Run mode 1 to extract features first.');
    end
    
    fprintf('Loaded %d test samples for demonstration.\n', length(testFeatures));
    
    % Create the main figure with professional layout
    fig = figure('Name', 'Lip Reading Simulation', 'Position', [50, 50, 1300, 800], ...
        'Color', [0.15, 0.15, 0.15], 'Menubar', 'none');
    
    % Title at the top
    uicontrol('Style', 'text', 'String', 'LIP READING SYSTEM DEMONSTRATION', ...
        'Position', [300, 765, 700, 30], 'FontSize', 20, 'FontWeight', 'bold', ...
        'ForegroundColor', [1, 1, 1], 'BackgroundColor', [0.15, 0.15, 0.15]);
    
    % Create panels
    lipMovementPanel = uipanel('Title', 'Lip Movement Simulation', 'FontSize', 14, ...
        'BackgroundColor', [0.2, 0.2, 0.2], 'ForegroundColor', [1, 1, 1], ...
        'Position', [0.05, 0.45, 0.45, 0.4], 'TitlePosition', 'centertop');
    
    featurePanel = uipanel('Title', 'Feature Extraction', 'FontSize', 14, ...
        'BackgroundColor', [0.2, 0.2, 0.2], 'ForegroundColor', [1, 1, 1], ...
        'Position', [0.55, 0.45, 0.4, 0.4], 'TitlePosition', 'centertop');
    
    decisionPanel = uipanel('Title', 'Decision Process', 'FontSize', 14, ...
        'BackgroundColor', [0.2, 0.2, 0.2], 'ForegroundColor', [1, 1, 1], ...
        'Position', [0.05, 0.05, 0.45, 0.35], 'TitlePosition', 'centertop');
    
    resultsPanel = uipanel('Title', 'Recognition Results', 'FontSize', 14, ...
        'BackgroundColor', [0.2, 0.2, 0.2], 'ForegroundColor', [1, 1, 1], ...
        'Position', [0.55, 0.05, 0.4, 0.35], 'TitlePosition', 'centertop');
    
    % Control buttons
    nextButton = uicontrol('Style', 'pushbutton', 'String', 'NEXT SAMPLE', ...
        'Position', [550, 730, 150, 30], 'Callback', @nextSample, ...
        'FontWeight', 'bold', 'BackgroundColor', [0.3, 0.6, 0.3], 'ForegroundColor', [1, 1, 1]);
    
    autoButton = uicontrol('Style', 'togglebutton', 'String', 'AUTO PLAY', ...
        'Position', [710, 730, 150, 30], 'Callback', @toggleAutoPlay, ...
        'FontWeight', 'bold', 'BackgroundColor', [0.6, 0.3, 0.3], 'ForegroundColor', [1, 1, 1]);
    
    speedSlider = uicontrol('Style', 'slider', 'Min', 0.5, 'Max', 3, 'Value', 1.5, ...
        'Position', [870, 735, 100, 20], 'Callback', @updateSpeed);
    
    uicontrol('Style', 'text', 'String', 'Speed:', 'Position', [870, 755, 50, 20], ...
        'ForegroundColor', [1, 1, 1], 'BackgroundColor', [0.15, 0.15, 0.15], 'HorizontalAlignment', 'left');
    
    % Create axes for each panel
    lipAxes = axes('Parent', lipMovementPanel, 'Position', [0.1, 0.15, 0.8, 0.75], ...
        'Color', [0.25, 0.25, 0.25], 'XColor', [0.8, 0.8, 0.8], 'YColor', [0.8, 0.8, 0.8]);
    
    featureAxes = axes('Parent', featurePanel, 'Position', [0.1, 0.15, 0.8, 0.75], ...
        'Color', [0.25, 0.25, 0.25], 'XColor', [0.8, 0.8, 0.8], 'YColor', [0.8, 0.8, 0.8]);
    
    decisionAxes = axes('Parent', decisionPanel, 'Position', [0.1, 0.15, 0.8, 0.75], ...
        'Color', [0.25, 0.25, 0.25], 'XColor', [0.8, 0.8, 0.8], 'YColor', [0.8, 0.8, 0.8]);
    
    resultsAxes = axes('Parent', resultsPanel, 'Position', [0.1, 0.15, 0.8, 0.75], ...
        'Color', [0.25, 0.25, 0.25], 'XColor', [0.8, 0.8, 0.8], 'YColor', [0.8, 0.8, 0.8]);
    
    % Status and information display
    statusText = uicontrol('Style', 'text', 'String', 'Ready to start demonstration', ...
        'Position', [50, 730, 400, 30], 'FontSize', 12, 'HorizontalAlignment', 'left', ...
        'ForegroundColor', [1, 1, 1], 'BackgroundColor', [0.15, 0.15, 0.15]);
    
    % Variables for tracking state
    currentSample = 0;
    totalSamples = length(testFeatures);
    isAutoPlaying = false;
    animationSpeed = 1.5;
    
    % Initialize results tracking
    results = struct('actual', {}, 'predicted', {}, 'correct', {});
    
    % Set up timer for auto play
    autoTimer = timer('ExecutionMode', 'fixedRate', 'Period', 4, ...
        'TimerFcn', @(~,~) nextSample([],[]), 'StopFcn', @(~,~) disp('Auto play stopped'));
    
    % Start the demo
    updateStatus('Press NEXT SAMPLE to begin demonstration');
    
    % Main demo functions
    function nextSample(~, ~)
        % Process the next sample
        currentSample = currentSample + 1;
        if currentSample > totalSamples
            currentSample = 1; % Loop back to start
        end
        
        % Get the current sample
        sample = testFeatures{currentSample};
        actualLabel = testLabels(currentSample);
        
        % Update status
        updateStatus(sprintf('Processing sample %d/%d (Actual: %s)', ...
            currentSample, totalSamples, char(actualLabel)));
        
        % Run the full demo sequence
        runDemoSequence(sample, actualLabel);
    end
    
    function toggleAutoPlay(src, ~)
        % Toggle auto play mode
        isAutoPlaying = get(src, 'Value');
        
        if isAutoPlaying
            set(src, 'String', 'STOP AUTO', 'BackgroundColor', [0.8, 0.3, 0.3]);
            updateStatus('Auto play mode: ON');
            start(autoTimer);
        else
            set(src, 'String', 'AUTO PLAY', 'BackgroundColor', [0.6, 0.3, 0.3]);
            updateStatus('Auto play mode: OFF');
            stop(autoTimer);
        end
    end
    
    function updateSpeed(src, ~)
        % Update animation speed
        animationSpeed = get(src, 'Value');
        autoTimer.Period = 5 / animationSpeed;
        updateStatus(sprintf('Animation speed: %.1fx', animationSpeed));
    end
    
    function updateStatus(message)
        % Update status text
        set(statusText, 'String', message);
    end
    
    function runDemoSequence(sample, actualLabel)
        % Run the full demonstration sequence for this sample
        
        % 1. Animate lip movement
        animateLipMovement(sample);
        
        % 2. Show feature extraction
        visualizeFeatures(sample);
        
        % 3. Simulate decision process
        predictedLabel = simulateDecision(sample, actualLabel);
        
        % 4. Display results
        updateResults(actualLabel, predictedLabel);
    end
    
    function animateLipMovement(sample)
        % Create an animation of lip movement from the sample features
        
        % Clear the axes
        cla(lipAxes);
        
        % Get relevant features
        width = sample.width;
        height = sample.height;
        centroidX = sample.centroidX;
        centroidY = sample.centroidY;
        
        % Normalize for visualization
        frameCount = length(width);
        
        % Title
        title(lipAxes, 'Simulated Lip Movement', 'Color', [1, 1, 1], 'FontSize', 12);
        xlabel(lipAxes, 'X Position', 'Color', [0.8, 0.8, 0.8]);
        ylabel(lipAxes, 'Y Position', 'Color', [0.8, 0.8, 0.8]);
        
        % Base face shape (static)
        t = linspace(0, 2*pi, 100);
        faceX = cos(t) * 4;
        faceY = sin(t) * 5 - 1; % Slightly elongated face
        
        % Plot face outline (stays static)
        hold(lipAxes, 'on');
        face = plot(lipAxes, faceX, faceY, 'Color', [0.8, 0.8, 0.8], 'LineWidth', 1.5);
        
        % Simple eyes (static)
        leftEye = plot(lipAxes, -1.5, 1, 'o', 'MarkerSize', 8, 'MarkerFaceColor', [0.8, 0.8, 0.8], 'Color', [0.5, 0.5, 0.5]);
        rightEye = plot(lipAxes, 1.5, 1, 'o', 'MarkerSize', 8, 'MarkerFaceColor', [0.8, 0.8, 0.8], 'Color', [0.5, 0.5, 0.5]);
        
        % Normalize mouth position to face
        normWidth = width / max(width) * 2.5;
        normHeight = height / max(height) * 1.5;
        
        % Create lip movement animation
        lips = rectangle('Position', [-normWidth(1)/2, -2.5, normWidth(1), normHeight(1)], ...
            'Curvature', [0.8, 0.8], 'FaceColor', [0.8, 0.2, 0.2], 'EdgeColor', [0.9, 0.3, 0.3]);
        
        % Set axis limits
        axis(lipAxes, [-5, 5, -6, 4]);
        
        % Animation frames
        frameDelay = 0.05 / animationSpeed;
        progressStep = 1 / frameCount;
        progressBar = rectangle('Position', [0, -5.8, 0, 0.3], 'FaceColor', [0.3, 0.6, 0.3], 'EdgeColor', 'none');
        
        % Progress text
        progressText = text(0, -5.4, '0%', 'Parent', lipAxes, 'HorizontalAlignment', 'center', ...
            'Color', [1, 1, 1], 'FontSize', 10);
        
        % Animate lip movement
        for i = 1:frameCount
            % Update lip shape
            set(lips, 'Position', [-normWidth(i)/2, -2.5, normWidth(i), normHeight(i)]);
            
            % Update progress bar
            set(progressBar, 'Position', [-5, -5.8, 10*i/frameCount, 0.3]);
            set(progressText, 'String', sprintf('%d%%', round(100*i/frameCount)));
            
            % Force drawing update
            drawnow;
            pause(frameDelay);
        end
        
        % Hold final frame briefly
        pause(0.5 / animationSpeed);
    end
    
    function visualizeFeatures(sample)
        % Visualize the features being extracted
        
        % Clear the axes
        cla(featureAxes);
        
        % Get relevant time series features
        lipRatio = sample.lipRatio;
        area = sample.area / max(sample.area); % Normalize for visualization
        centroidMovement = sqrt(diff(sample.centroidX).^2 + diff(sample.centroidY).^2);
        centroidMovement = [0; centroidMovement] / max(max(centroidMovement), 1); % Normalize
        
        % Time points
        t = 1:length(lipRatio);
        
        % Setup plot
        hold(featureAxes, 'on');
        title(featureAxes, 'Feature Extraction', 'Color', [1, 1, 1], 'FontSize', 12);
        xlabel(featureAxes, 'Frame', 'Color', [0.8, 0.8, 0.8]);
        ylabel(featureAxes, 'Value', 'Color', [0.8, 0.8, 0.8]);
        
        % Plot grid
        grid(featureAxes, 'on');
        set(featureAxes, 'GridColor', [0.3, 0.3, 0.3]);
        
        % Animation
        frameDelay = 0.02 / animationSpeed;
        numFrames = length(lipRatio);
        
        % Plot animated lines
        p1 = plot(featureAxes, [0], [0], 'r-', 'LineWidth', 2, 'DisplayName', 'Lip Ratio');
        p2 = plot(featureAxes, [0], [0], 'g-', 'LineWidth', 2, 'DisplayName', 'Area (norm)');
        p3 = plot(featureAxes, [0], [0], 'b-', 'LineWidth', 2, 'DisplayName', 'Movement');
        
        % Legend
        legend(featureAxes, 'show', 'TextColor', [1, 1, 1], 'Color', [0.25, 0.25, 0.25], 'EdgeColor', [0.4, 0.4, 0.4]);
        
        % Feature visibility checkboxes
        uicontrol('Style', 'checkbox', 'String', 'Lip Ratio', 'Value', 1, ...
            'Position', [featurePanel.Position(1)*1300+20, featurePanel.Position(2)*800+15, 80, 20], ...
            'Callback', @(src,~) set(p1, 'Visible', get_visibility(src)), ...
            'ForegroundColor', [1, 0.2, 0.2], 'BackgroundColor', [0.25, 0.25, 0.25]);
        
        uicontrol('Style', 'checkbox', 'String', 'Area', 'Value', 1, ...
            'Position', [featurePanel.Position(1)*1300+110, featurePanel.Position(2)*800+15, 60, 20], ...
            'Callback', @(src,~) set(p2, 'Visible', get_visibility(src)), ...
            'ForegroundColor', [0.2, 1, 0.2], 'BackgroundColor', [0.25, 0.25, 0.25]);
        
        uicontrol('Style', 'checkbox', 'String', 'Movement', 'Value', 1, ...
            'Position', [featurePanel.Position(1)*1300+180, featurePanel.Position(2)*800+15, 80, 20], ...
            'Callback', @(src,~) set(p3, 'Visible', get_visibility(src)), ...
            'ForegroundColor', [0.2, 0.2, 1], 'BackgroundColor', [0.25, 0.25, 0.25]);
        
        % Set axis limits
        xlim(featureAxes, [1, numFrames]);
        ylim(featureAxes, [0, 1.2]);
        
        % Animate drawing
        for i = 2:numFrames
            % Update line data
            set(p1, 'XData', t(1:i), 'YData', lipRatio(1:i));
            set(p2, 'XData', t(1:i), 'YData', area(1:i));
            set(p3, 'XData', t(1:i), 'YData', centroidMovement(1:i));
            
            % Add feature extraction markers
            if i == round(numFrames/4) || i == round(numFrames/2) || i == round(3*numFrames/4)
                % Highlight extraction points
                plot(featureAxes, i, lipRatio(i), 'ro', 'MarkerSize', 8, 'MarkerFaceColor', 'r');
                plot(featureAxes, i, area(i), 'go', 'MarkerSize', 8, 'MarkerFaceColor', 'g');
                plot(featureAxes, i, centroidMovement(i), 'bo', 'MarkerSize', 8, 'MarkerFaceColor', 'b');
                
                % Add measurement text
                text(i, lipRatio(i)+0.1, sprintf('%.2f', lipRatio(i)), 'Parent', featureAxes, ...
                    'Color', 'r', 'FontSize', 8);
                text(i, area(i)+0.1, sprintf('%.2f', area(i)), 'Parent', featureAxes, ...
                    'Color', 'g', 'FontSize', 8);
                text(i, centroidMovement(i)+0.1, sprintf('%.2f', centroidMovement(i)), 'Parent', featureAxes, ...
                    'Color', 'b', 'FontSize', 8);
            end
            
            % Force drawing update
            drawnow;
            pause(frameDelay);
        end
        
        % Calculate summary statistics (mean, std, etc)
        featureStats = struct();
        featureStats.lipRatioMean = mean(lipRatio);
        featureStats.lipRatioStd = std(lipRatio);
        featureStats.areaMean = mean(area);
        featureStats.areaVariation = std(area) / mean(area);
        featureStats.movementTotal = sum(centroidMovement);
        
        % Display summary box
        summaryBox = annotation('textbox', ...
            [featurePanel.Position(1)+0.05, featurePanel.Position(2)+0.05, 0.3, 0.1], ...
            'String', {
                'Feature Summary:', ...
                sprintf('Lip Ratio: %.2f (σ=%.2f)', featureStats.lipRatioMean, featureStats.lipRatioStd), ...
                sprintf('Area Variation: %.2f%%', featureStats.areaVariation*100), ...
                sprintf('Movement: %.2f', featureStats.movementTotal)
            }, ...
            'EdgeColor', [0.7, 0.7, 0.7], ...
            'BackgroundColor', [0.3, 0.3, 0.3, 0.7], ...
            'Color', [1, 1, 1], ...
            'FontSize', 9);
        
        % Pause to view
        pause(0.5 / animationSpeed);
    end
    
    function predictedLabel = simulateDecision(sample, actualLabel)
        % Visualize the decision process
        
        % Clear the axes
        cla(decisionAxes);
        
        % Set up the visualization
        title(decisionAxes, 'Model Decision Process', 'Color', [1, 1, 1], 'FontSize', 12);
        hold(decisionAxes, 'on');
        
        % Calculate feature vector (normalized for visualization)
        featureLabels = {'Lip Ratio', 'LR Variation', 'Area', 'Area Var', 'Movement', 'Range', 'Ratio'};
        featureValues = [
            mean(sample.lipRatio),
            std(sample.lipRatio),
            mean(sample.area) / 1000, % Scale down for visibility
            std(sample.area) / mean(sample.area),
            std(sample.centroidX) + std(sample.centroidY),
            max(sample.lipRatio) - min(sample.lipRatio),
            max(sample.area) / min(sample.area) / 10 % Scale down for visibility
        ];
        
        % Normalize feature values for visualization
        maxVal = max(featureValues);
        featureValues = featureValues / maxVal;
        
        % Create a bar chart of feature values
        barH = bar(decisionAxes, featureValues, 'FaceColor', 'flat');
        
        % Set bar colors based on importance (simulated)
        importanceColors = [0.8, 0.2, 0.2; 0.7, 0.3, 0.3; 0.6, 0.4, 0.4; 
                          0.5, 0.5, 0.5; 0.4, 0.4, 0.6; 0.3, 0.3, 0.7; 0.2, 0.2, 0.8];
        
        % Animate feature loading
        for i = 1:length(featureValues)
            barH.CData(i,:) = importanceColors(i,:);
            barH.YData(i) = featureValues(i);
            
            % Add value label
            text(i, featureValues(i) + 0.05, sprintf('%.2f', featureValues(i)), ...
                'HorizontalAlignment', 'center', 'Color', [1, 1, 1], 'Parent', decisionAxes);
            
            drawnow;
            pause(0.2 / animationSpeed);
        end
        
        % Set axis labels
        set(decisionAxes, 'XTick', 1:length(featureLabels), 'XTickLabel', featureLabels);
        set(decisionAxes, 'XTickLabelRotation', 45);
        ylim(decisionAxes, [0, 1.2]);
        
        % Get the actual prediction from the model
        try
            tic; % Start timer
            predictedLabel = model.predict(sample);
            predictionTime = toc; % End timer
            
            if ~ischar(predictedLabel) && iscategorical(predictedLabel)
                predictedLabel = char(predictedLabel);
            end
        catch e
            warning('Error in prediction: %s', e.message);
            predictedLabel = 'Error';
            predictionTime = 0;
        end
        
        % Simulate confidences
        confidences = simulateConfidenceValues(wordClasses, predictedLabel);
        
        % Display model decision process
        decisionText = sprintf('Prediction: %s (%.1f ms)', predictedLabel, predictionTime*1000);
        text(4, 1.1, decisionText, 'HorizontalAlignment', 'center', ...
            'FontWeight', 'bold', 'FontSize', 12, 'Color', [1, 1, 1], 'Parent', decisionAxes);
        
        % Highlight the decision path
        annotation('arrow', [0.27, 0.27], [0.25, 0.15], 'Color', [0.8, 0.8, 0.2], 'LineWidth', 2);
        
        % Pause to view
        pause(0.5 / animationSpeed);
        
        return;
    end
    
    function updateResults(actualLabel, predictedLabel)
        % Update and display the results
        
        % Clear the axes
        cla(resultsAxes);
        
        % Store result
        isCorrect = strcmpi(char(actualLabel), predictedLabel);
        results(end+1).actual = char(actualLabel);
        results(end).predicted = predictedLabel;
        results(end).correct = isCorrect;
        
        % Display confidence bars
        confidences = simulateConfidenceValues(wordClasses, predictedLabel);
        barH = bar(resultsAxes, 1:length(wordClasses), confidences, 'FaceColor', 'flat');
        
        % Set bar colors
        for i = 1:length(wordClasses)
            if strcmpi(wordClasses{i}, predictedLabel)
                barH.CData(i,:) = [0.2, 0.8, 0.3]; % Green for predicted class
            else
                barH.CData(i,:) = [0.4, 0.4, 0.7]; % Blue for other classes
            end
        end
        
        % Set axis labels
        title(resultsAxes, 'Recognition Results', 'Color', [1, 1, 1], 'FontSize', 12);
        xlabel(resultsAxes, 'Classes', 'Color', [0.8, 0.8, 0.8]);
        ylabel(resultsAxes, 'Confidence', 'Color', [0.8, 0.8, 0.8]);
        set(resultsAxes, 'XTick', 1:length(wordClasses), 'XTickLabel', wordClasses);
        set(resultsAxes, 'XTickLabelRotation', 30);
        ylim(resultsAxes, [0, 1]);
        
        % Add value labels to bars
        for i = 1:length(confidences)
            text(i, confidences(i) + 0.05, sprintf('%.0f%%', confidences(i)*100), ...
                'HorizontalAlignment', 'center', 'Color', [1, 1, 1], 'Parent', resultsAxes);
        end
        
        % Display current result
        resultText = sprintf('Actual: %s | Predicted: %s', char(actualLabel), predictedLabel);
        resultColor = [0.2, 0.8, 0.3]; % Green for correct
        if ~isCorrect
            resultColor = [0.8, 0.3, 0.3]; % Red for incorrect
        end
        
        % Add animated result indicator 
        resultIndicator = uicontrol('Style', 'text', 'String', resultText, ...
            'Position', [resultsPanel.Position(1)*1300+50, resultsPanel.Position(2)*800+10, 300, 25], ...
            'BackgroundColor', resultColor, 'ForegroundColor', [1, 1, 1], ...
            'FontWeight', 'bold', 'FontSize', 12);
        
        % Flash if correct
        if isCorrect
            for i = 1:3
                set(resultIndicator, 'BackgroundColor', [0.3, 0.9, 0.4]);
                pause(0.1 / animationSpeed);
                set(resultIndicator, 'BackgroundColor', [0.2, 0.7, 0.3]);
                pause(0.1 / animationSpeed);
            end
        end
        
        % Calculate and display accuracy
        correct = sum([results.correct]);
        accuracy = correct / length(results) * 100;
        
        accuracyText = sprintf('Overall Accuracy: %d/%d (%.1f%%)', ...
            correct, length(results), accuracy);
        
        uicontrol('Style', 'text', 'String', accuracyText, ...
            'Position', [resultsPanel.Position(1)*1300+50, resultsPanel.Position(2)*800+40, 300, 20], ...
            'BackgroundColor', [0.3, 0.3, 0.3], 'ForegroundColor', [1, 1, 1], ...
            'FontSize', 10);
    end
    
    function visibility = get_visibility(hndl)
        % Helper to toggle visibility based on checkbox
        if get(hndl, 'Value') == 1
            visibility = 'on';
        else
            visibility = 'off';
        end
    end
    
    % Clean up function
    function cleanup
        % Stop timer if running
        if exist('autoTimer', 'var') && isvalid(autoTimer) && strcmp(autoTimer.Running, 'on')
            stop(autoTimer);
        end
        
        % Delete timer
        if exist('autoTimer', 'var') && isvalid(autoTimer)
            delete(autoTimer);
        end
    end

    % Set cleanup function to run when figure is closed
    set(fig, 'CloseRequestFcn', @(~,~) closeDemo);
    
    function closeDemo
        % Clean up and close
        cleanup();
        delete(fig);
    end
end

function [testFeatures, testLabels] = extractValidationSet(features, labels, ratio)
    % Extract a validation set ensuring at least one sample per class
    
    % Get unique classes
    classes = categories(labels);
    
    testFeatures = {};
    testLabels = categorical([]);
    
    % Process each class to ensure representation
    for i = 1:length(classes)
        % Find samples of this class
        classIndices = find(labels == classes{i});
        
        % Determine how many to use (at least 1, at most ratio of available)
        numSamples = length(classIndices);
        numTest = max(1, round(numSamples * ratio));
        
        % Randomly select samples
        rng(42 + i); % For reproducibility
        selectedIndices = classIndices(randperm(numSamples, numTest));
        
        % Add to test set
        for j = 1:length(selectedIndices)
            testFeatures{end+1} = features{selectedIndices(j)};
            testLabels(end+1) = labels(selectedIndices(j));
        end
    end
end

function confidences = simulateConfidenceValues(wordClasses, prediction)
    % Create simulated confidence values for demonstration purposes
    
    % Initialize confidence vector
    confidences = zeros(length(wordClasses), 1);
    
    % Find the index of the predicted class
    predIdx = find(strcmpi(wordClasses, prediction));
    
    if ~isempty(predIdx)
        % Set high confidence for the predicted class
        confidences(predIdx) = 0.7 + 0.3*rand(); % Between 0.7 and 1.0
        
        % Set low confidence for other classes
        for i = 1:length(wordClasses)
            if i ~= predIdx
                confidences(i) = 0.1*rand(); % Between 0 and 0.1
            end
        end
    else
        % If prediction not in wordClasses, set random values
        confidences = 0.3*rand(length(wordClasses), 1);
    end
    
    % Normalize to ensure sum is 1
    confidences = confidences / sum(confidences);
end