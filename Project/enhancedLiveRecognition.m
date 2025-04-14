function enhancedLiveRecognition(model, wordClasses)
    % Enhanced live recognition with better visualizations for demonstrations
    
    % Initialize webcam
    try
        cam = webcam();
    catch e
        error('Could not initialize webcam: %s', e.message);
    end
    
    % Create main figure with better layout
    fig = figure('Name', 'Lip Reading Demonstration', 'Position', [100, 100, 1200, 700], ...
        'Color', [0.95, 0.95, 0.95]);
    
    % Set up the layout
    % Camera feed panel
    cameraPanel = uipanel('Title', 'Camera Feed', 'Position', [0.05, 0.45, 0.45, 0.5], ...
        'BackgroundColor', [0.95, 0.95, 0.95], 'FontSize', 12, 'FontWeight', 'bold');
    
    % Lip detection panel
    lipPanel = uipanel('Title', 'Lip Detection', 'Position', [0.55, 0.45, 0.40, 0.5], ...
        'BackgroundColor', [0.95, 0.95, 0.95], 'FontSize', 12, 'FontWeight', 'bold');
    
    % Feature visualization panel
    featurePanel = uipanel('Title', 'Feature Visualization', 'Position', [0.05, 0.07, 0.45, 0.35], ...
        'BackgroundColor', [0.95, 0.95, 0.95], 'FontSize', 12, 'FontWeight', 'bold');
    
    % Recognition results panel
    resultsPanel = uipanel('Title', 'Recognition Results', 'Position', [0.55, 0.07, 0.40, 0.35], ...
        'BackgroundColor', [0.95, 0.95, 0.95], 'FontSize', 12, 'FontWeight', 'bold');
    
    % Create UI controls
    uicontrol('Style', 'pushbutton', 'String', 'Start Recording', ...
        'Position', [50, 20, 120, 30], 'Callback', @startRecording, ...
        'BackgroundColor', [0.3, 0.6, 0.3], 'ForegroundColor', 'white', 'FontWeight', 'bold');
    
    uicontrol('Style', 'pushbutton', 'String', 'Stop/Recognize', ...
        'Position', [180, 20, 120, 30], 'Callback', @stopRecording, ...
        'BackgroundColor', [0.6, 0.3, 0.3], 'ForegroundColor', 'white', 'FontWeight', 'bold');
    
    uicontrol('Style', 'pushbutton', 'String', 'Exit', ...
        'Position', [310, 20, 80, 30], 'Callback', @exitApp, ...
        'BackgroundColor', [0.4, 0.4, 0.4], 'ForegroundColor', 'white');
    
    % Create a separate axes for the status light
    statusAxes = axes('Position', [0.35, 0.01, 0.05, 0.05]);
    axis(statusAxes, 'off');
    
    % Status indicator light
    statusLight = rectangle('Position', [0.25, 0.25, 0.5, 0.5], 'Curvature', [1, 1], ...
        'FaceColor', [0.7, 0.7, 0.7], 'Parent', statusAxes);
        
    statusText = uicontrol('Style', 'text', 'String', 'READY', ...
        'Position', [460, 20, 100, 30], 'HorizontalAlignment', 'left', ...
        'FontWeight', 'bold', 'FontSize', 12);
    
    % Display area for results
    resultText = uicontrol('Style', 'text', 'String', 'Press "Start Recording" to begin...', ...
        'Position', [580, 20, 400, 30], 'FontSize', 12, 'HorizontalAlignment', 'left', ...
        'FontWeight', 'bold');
    
    % Create axes for each panel
    axes('Parent', cameraPanel, 'Position', [0.05, 0.05, 0.9, 0.9]);
    cameraAxes = gca;
    
    axes('Parent', lipPanel, 'Position', [0.05, 0.05, 0.9, 0.9]);
    lipAxes = gca;
    
    axes('Parent', featurePanel, 'Position', [0.08, 0.15, 0.9, 0.8]);
    featureAxes = gca;
    
    axes('Parent', resultsPanel, 'Position', [0.1, 0.15, 0.85, 0.8]);
    resultsAxes = gca;
    
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
    
    % Setup confidence bars
    confidences = zeros(length(wordClasses), 1);
    barH = bar(resultsAxes, 1:length(wordClasses), confidences, 'FaceColor', 'flat');
    for i = 1:length(wordClasses)
        barH.CData(i,:) = hsv2rgb([(i-1)/length(wordClasses), 0.8, 0.9]);
    end
    title(resultsAxes, 'Word Confidence Levels');
    xlabel(resultsAxes, 'Words');
    ylabel(resultsAxes, 'Confidence');
    set(resultsAxes, 'XTick', 1:length(wordClasses), 'XTickLabel', wordClasses);
    set(resultsAxes, 'YLim', [0 1]);
    
    % Feature plot setup
    featureLine = plot(featureAxes, 0, 0, 'r-', 'LineWidth', 2);
    title(featureAxes, 'Lip Ratio Over Time');
    xlabel(featureAxes, 'Frame');
    ylabel(featureAxes, 'Lip Ratio (Height/Width)');
    grid(featureAxes, 'on');
    
    % Recognition history
    recognitionHistory = {};
    
    % Main loop
    while ishandle(fig)
        % Capture frame
        frame = snapshot(cam);
        
        % Process frame to extract lip region
        [lipMask, lipFeatures] = processLipFrame(frame);
        
        % Display original frame
        imshow(frame, 'Parent', cameraAxes);
        title(cameraAxes, 'Camera Feed');
        
        % If lip features were found, overlay them
        if ~isempty(lipFeatures) && lipFeatures.LipFound
            hold(cameraAxes, 'on');
            rectangle('Position', lipFeatures.BoundingBox, 'EdgeColor', 'r', 'LineWidth', 2, 'Parent', cameraAxes);
            plot(cameraAxes, lipFeatures.Centroid(1), lipFeatures.Centroid(2), 'g+', 'MarkerSize', 10);
            hold(cameraAxes, 'off');
            
            % Display lip mask with overlay
            imshow(lipMask, 'Parent', lipAxes);
            title(lipAxes, 'Detected Lip Region');
            
            % If recording, store features
            if isRecording
                % Update status indicator
                set(statusLight, 'FaceColor', [0.2, 0.8, 0.2]);
                set(statusText, 'String', 'RECORDING', 'ForegroundColor', [0.2, 0.8, 0.2]);
                
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
                    % Update feature plot
                    set(featureLine, 'XData', 1:frameCount, 'YData', featureStruct.lipRatio);
                    set(featureAxes, 'XLim', [1, max(20, frameCount)]);
                    set(featureAxes, 'YLim', [min(featureStruct.lipRatio)-0.1, max(featureStruct.lipRatio)+0.1]);
                end
            else
                % Update status indicator
                set(statusLight, 'FaceColor', [0.7, 0.7, 0.2]);
                set(statusText, 'String', 'READY', 'ForegroundColor', [0.7, 0.7, 0.2]);
            end
        else
            % No lips detected
            imshow(zeros(size(frame, 1), size(frame, 2)), 'Parent', lipAxes);
            title(lipAxes, 'No Lips Detected');
            
            if isRecording
                set(statusLight, 'FaceColor', [0.8, 0.4, 0.1]);
                set(statusText, 'String', 'NO LIPS', 'ForegroundColor', [0.8, 0.4, 0.1]);
                set(resultText, 'String', 'Recording paused - No lips detected');
            else
                set(statusLight, 'FaceColor', [0.7, 0.7, 0.7]);
                set(statusText, 'String', 'READY', 'ForegroundColor', [0.5, 0.5, 0.5]);
            end
        end
        
        % Keep confidence graph updated
        if ~isRecording && ~isempty(recognitionHistory) && length(recognitionHistory) > 0
            updateConfidenceGraph(resultsAxes, wordClasses, recognitionHistory);
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
        set(statusLight, 'FaceColor', [0.2, 0.8, 0.2]);
        set(statusText, 'String', 'RECORDING', 'ForegroundColor', [0.2, 0.8, 0.2]);
        
        % Reset feature plot
        set(featureLine, 'XData', [], 'YData', []);
        title(featureAxes, 'Lip Ratio Over Time');
    end
    
    function stopRecording(~, ~)
        % Stop recording
        isRecording = false;
        set(statusLight, 'FaceColor', [0.7, 0.7, 0.2]);
        set(statusText, 'String', 'PROCESSING', 'ForegroundColor', [0.7, 0.7, 0.2]);
        
        % Check if enough frames were recorded
        if frameCount < 10
            set(resultText, 'String', 'Not enough frames recorded. Try again.');
            set(statusLight, 'FaceColor', [0.8, 0.2, 0.2]);
            set(statusText, 'String', 'ERROR', 'ForegroundColor', [0.8, 0.2, 0.2]);
            return;
        end
        
        % Make prediction
        try
            % Use our custom predict method
            prediction = model.predict(featureStruct);
            
            % Create a confidence histogram (simulate confidences for demonstration)
            confidences = simulateConfidenceValues(wordClasses, prediction);
            
            % Update confidence graph
            updateConfidenceGraph(resultsAxes, wordClasses, {{prediction, confidences}});
            
            % Add to recognition history
            recognitionHistory{end+1} = {prediction, confidences};
            if length(recognitionHistory) > 5
                recognitionHistory = recognitionHistory(end-4:end);
            end
            
            % Update UI
            set(resultText, 'String', sprintf('Recognized: %s', prediction));
            set(statusLight, 'FaceColor', [0.2, 0.6, 0.8]);
            set(statusText, 'String', 'RECOGNIZED', 'ForegroundColor', [0.2, 0.6, 0.8]);
            
            % Flash the recognized word in the confidence graph
            highlightRecognizedWord(resultsAxes, wordClasses, prediction);
            
        catch e
            set(resultText, 'String', sprintf('Error in prediction: %s', e.message));
            set(statusLight, 'FaceColor', [0.8, 0.2, 0.2]);
            set(statusText, 'String', 'ERROR', 'ForegroundColor', [0.8, 0.2, 0.2]);
        end
    end
    
    function exitApp(~, ~)
        close(fig);
    end
end