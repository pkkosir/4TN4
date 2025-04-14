%% Additional functions for demonstration purposes

function visualizeTrainingStats(features, labels, augFeatures, augLabels)
    % Visualize statistics about original and augmented datasets
    
    % Create a figure
    figure('Name', 'Dataset Statistics', 'Position', [100, 100, 1000, 800]);
    
    % Class distribution
    subplot(2, 2, 1);
    origCounts = countcats(labels);
    augCounts = countcats(augLabels);
    
    % Plot as grouped bar chart
    cats = categories(labels);
    bar([origCounts, augCounts]);
    legend('Original', 'Augmented');
    title('Class Distribution');
    xlabel('Class');
    ylabel('Count');
    set(gca, 'XTick', 1:length(cats), 'XTickLabel', cats);
    
    % Feature means
    subplot(2, 2, 2);
    
    % Extract mean feature values
    featureNames = {'Lip Ratio', 'Area', 'Width', 'Height'};
    origMeans = zeros(length(cats), length(featureNames));
    augMeans = zeros(length(cats), length(featureNames));
    
    % Calculate means for original data
    for i = 1:length(cats)
        classIndices = find(labels == cats{i});
        for j = 1:length(classIndices)
            sample = features{classIndices(j)};
            origMeans(i, 1) = origMeans(i, 1) + mean(sample.lipRatio);
            origMeans(i, 2) = origMeans(i, 2) + mean(sample.area);
            origMeans(i, 3) = origMeans(i, 3) + mean(sample.width);
            origMeans(i, 4) = origMeans(i, 4) + mean(sample.height);
        end
        origMeans(i, :) = origMeans(i, :) / length(classIndices);
    end
    
    % Calculate means for augmented data
    for i = 1:length(cats)
        classIndices = find(augLabels == cats{i});
        for j = 1:min(50, length(classIndices)) % Limit to 50 samples per class
            sample = augFeatures{classIndices(j)};
            augMeans(i, 1) = augMeans(i, 1) + mean(sample.lipRatio);
            augMeans(i, 2) = augMeans(i, 2) + mean(sample.area);
            augMeans(i, 3) = augMeans(i, 3) + mean(sample.width);
            augMeans(i, 4) = augMeans(i, 4) + mean(sample.height);
        end
        augMeans(i, :) = augMeans(i, :) / min(50, length(classIndices));
    end
    
    % Normalize for visualization
    for j = 1:length(featureNames)
        maxVal = max(max(origMeans(:, j)), max(augMeans(:, j)));
        origMeans(:, j) = origMeans(:, j) / maxVal;
        augMeans(:, j) = augMeans(:, j) / maxVal;
    end
    
    % Plot as radar chart
    hold on;
    for i = 1:length(cats)
        plot(origMeans(i, :), 'LineWidth', 2, 'DisplayName', [char(cats{i}) ' (orig)']);
        plot(augMeans(i, :), '--', 'LineWidth', 1.5, 'DisplayName', [char(cats{i}) ' (aug)']);
    end
    set(gca, 'XTick', 1:length(featureNames), 'XTickLabel', featureNames);
    title('Normalized Feature Means by Class');
    legend('Location', 'eastoutside');
    grid on;
    
    % Feature trajectories
    subplot(2, 2, 3:4);
    
    % Plot one original and one augmented sample for each class
    hold on;
    lineTypes = {'-', '--', ':', '-.', '-'};
    for i = 1:length(cats)
        % Get one original sample
        origIdx = find(labels == cats{i}, 1);
        if ~isempty(origIdx)
            origSample = features{origIdx};
            
            % Normalize time to 0-1 range
            normTime = linspace(0, 1, length(origSample.lipRatio));
            
            % Plot lip ratio
            plot(normTime, origSample.lipRatio, lineTypes{mod(i-1, length(lineTypes))+1}, ...
                'LineWidth', 2, 'Color', hsv2rgb([(i-1)/length(cats), 0.8, 0.9]), ...
                'DisplayName', [char(cats{i}) ' (orig)']);
        end
        
        % Get one augmented sample
        augIdx = find(augLabels == cats{i}, 1);
        if ~isempty(augIdx)
            augSample = augFeatures{augIdx};
            
            % Normalize time to 0-1 range
            normTime = linspace(0, 1, length(augSample.lipRatio));
            
            % Plot lip ratio
            plot(normTime, augSample.lipRatio, lineTypes{mod(i-1, length(lineTypes))+1}, ...
                'LineWidth', 1, 'Color', hsv2rgb([(i-1)/length(cats), 0.5, 0.7]), ...
                'DisplayName', [char(cats{i}) ' (aug)']);
        end
    end
    title('Lip Ratio Trajectories');
    xlabel('Normalized Time');
    ylabel('Lip Ratio (Height/Width)');
    legend('Location', 'eastoutside');
    grid on;
end