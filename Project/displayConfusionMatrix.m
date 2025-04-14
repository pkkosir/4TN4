function displayConfusionMatrix(model, testFeatures, testLabels)
    % Create and display a confusion matrix from model predictions
    
    try
        % Make predictions on test data
        numSamples = length(testFeatures);
        predictions = cell(numSamples, 1);
        
        fprintf('Generating predictions for %d test samples...\n', numSamples);
        
        % Process each test sample
        for i = 1:numSamples
            predictions{i} = model.predict(testFeatures{i});
            fprintf('.');
            if mod(i, 50) == 0
                fprintf(' %d/%d\n', i, numSamples);
            end
        end
        fprintf('\nPredictions complete.\n');
        
        % Convert to categorical for comparison
        predictedLabels = categorical(predictions);
        
        % Calculate metrics
        accuracy = sum(predictedLabels == testLabels) / numSamples;
        
        % Create confusion matrix
        figure('Name', 'Confusion Matrix', 'Position', [200, 200, 700, 500]);
        
        % Create confusion chart
        cm = confusionchart(testLabels, predictedLabels);
        cm.Title = sprintf('Lip Reading Confusion Matrix (Accuracy: %.1f%%)', accuracy * 100);
        cm.RowSummary = 'row-normalized';
        cm.ColumnSummary = 'column-normalized';
        
        % Additional metrics
        disp('Classification Report:');
        classes = categories(testLabels);
        
        fprintf('%-10s %-10s %-10s %-10s\n', 'Class', 'Precision', 'Recall', 'F1-Score');
        fprintf('-----------------------------------------------\n');
        
        % Calculate per-class metrics
        for i = 1:length(classes)
            % True positives: predicted and actual are this class
            tp = sum((predictedLabels == classes{i}) & (testLabels == classes{i}));
            
            % False positives: predicted as this class but actually a different class
            fp = sum((predictedLabels == classes{i}) & (testLabels ~= classes{i}));
            
            % False negatives: predicted as a different class but actually this class
            fn = sum((predictedLabels ~= classes{i}) & (testLabels == classes{i}));
            
            % Calculate metrics
            precision = tp / (tp + fp + eps);
            recall = tp / (tp + fn + eps);
            f1 = 2 * precision * recall / (precision + recall + eps);
            
            % Display
            fprintf('%-10s %-10.2f %-10.2f %-10.2f\n', classes{i}, precision, recall, f1);
        end
        
        fprintf('-----------------------------------------------\n');
        fprintf('Accuracy: %.2f%%\n', accuracy * 100);
        
    catch e
        warning('Error generating confusion matrix: %s', e.message);
        disp(getReport(e));
    end
end