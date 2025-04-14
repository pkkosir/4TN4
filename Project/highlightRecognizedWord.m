function highlightRecognizedWord(axesHandle, wordClasses, prediction)
    % Create a flashing highlight effect for the recognized word
    
    % Find the index of the predicted class
    predIdx = find(strcmp(wordClasses, prediction));
    
    if ~isempty(predIdx)
        % Get the bar object
        barH = findobj(axesHandle, 'Type', 'bar');
        
        if ~isempty(barH)
            % Get current colors
            currentColors = get(barH, 'CData');
            originalColor = currentColors(predIdx,:);
            
            % Flash the bar 3 times
            for i = 1:3
                % Change to bright yellow
                currentColors(predIdx,:) = [1, 1, 0];
                set(barH, 'CData', currentColors);
                drawnow;
                pause(0.1);
                
                % Change back to original color
                currentColors(predIdx,:) = originalColor;
                set(barH, 'CData', currentColors);
                drawnow;
                pause(0.1);
            end
        end
    end
end