function updateConfidenceGraph(axesHandle, wordClasses, recognitionHistory)
    % Update the confidence graph with the latest recognition
    
    % Get latest prediction
    latestRecognition = recognitionHistory{end};
    latestPrediction = latestRecognition{1};
    latestConfidences = latestRecognition{2};
    
    % Update bar heights
    barH = findobj(axesHandle, 'Type', 'bar');
    
    if ~isempty(barH)
        set(barH, 'YData', latestConfidences);
        
        % Highlight the predicted class
        predIdx = find(strcmp(wordClasses, latestPrediction));
        if ~isempty(predIdx)
            % Update colors - predicted class in green, others in original colors
            newColors = get(barH, 'CData');
            for i = 1:length(wordClasses)
                if i == predIdx
                    newColors(i,:) = [0.2, 0.8, 0.3]; % Green for predicted class
                else
                    newColors(i,:) = hsv2rgb([(i-1)/length(wordClasses), 0.8, 0.9]);
                end
            end
            set(barH, 'CData', newColors);
        end
    end
    
    % Update title with prediction
    title(axesHandle, sprintf('Prediction: %s', latestPrediction));
end