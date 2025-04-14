function [augmentedFeatures, augmentedLabels] = augmentLipData(features, labels, augFactor)
    % Augment lip reading data to create more training samples
    % 
    % Inputs:
    %   features - Cell array of feature structures
    %   labels - Categorical array of labels
    %   augFactor - How many augmented samples to create per original sample
    %
    % Outputs:
    %   augmentedFeatures - Cell array containing original and augmented features
    %   augmentedLabels - Categorical array containing original and augmented labels
    
    if nargin < 3
        augFactor = 5; % Default: create 5 augmented samples per original
    end
    
    fprintf('Augmenting dataset: %d original samples with factor %d\n', length(features), augFactor);
    
    % Initialize output arrays
    numOrigSamples = length(features);
    numAugSamples = numOrigSamples * augFactor;
    totalSamples = numOrigSamples + numAugSamples;
    
    augmentedFeatures = cell(totalSamples, 1);
    augmentedLabelsStr = cell(totalSamples, 1);
    
    % Copy original samples first
    for i = 1:numOrigSamples
        augmentedFeatures{i} = features{i};
        augmentedLabelsStr{i} = char(labels(i));
    end
    
    % Generate augmented samples
    augIndex = numOrigSamples + 1;
    
    % List of augmentation techniques
    augTechniques = {
        @timeStretch,          % Time stretching/compression
        @addNoise,             % Add noise to features
        @jitterPosition,       % Add jitter to positions
        @scaleFeatures,        % Scale features up/down
        @dropFrames            % Randomly drop some frames
    };
    
    % Apply augmentations
    for i = 1:numOrigSamples
        origSample = features{i};
        origLabel = labels(i);
        
        % Apply each technique multiple times to reach augFactor
        for j = 1:augFactor
            % Choose a random augmentation technique
            techniqueIdx = randi(length(augTechniques));
            augFunc = augTechniques{techniqueIdx};
            
            % Apply the augmentation
            augSample = augFunc(origSample);
            
            % Store the augmented sample
            augmentedFeatures{augIndex} = augSample;
            augmentedLabelsStr{augIndex} = char(origLabel);
            
            augIndex = augIndex + 1;
        end
        
        % Progress indicator
        if mod(i, 5) == 0 || i == numOrigSamples
            fprintf('Augmented %d/%d original samples\n', i, numOrigSamples);
        end
    end
    
    % Convert labels to categorical
    augmentedLabels = categorical(augmentedLabelsStr);
    
    fprintf('Augmentation complete: %d total samples (%d original + %d augmented)\n', ...
        length(augmentedFeatures), numOrigSamples, numAugSamples);
end
