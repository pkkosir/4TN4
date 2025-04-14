function confidences = simulateConfidenceValues(wordClasses, prediction)
    % Create simulated confidence values for demonstration purposes
    % In a real system, these would come from the model's prediction probabilities
    
    confidences = zeros(length(wordClasses), 1);
    
    % Find the index of the predicted class
    predIdx = find(strcmp(wordClasses, prediction));
    
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
        % If prediction not in wordClasses (shouldn't happen), set random values
        confidences = 0.3*rand(length(wordClasses), 1);
    end
    
    % Normalize to ensure sum is 1
    confidences = confidences / sum(confidences);
end