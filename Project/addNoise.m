function augSample = addNoise(sample)
    % Add small random noise to features
    noiseFactor = 0.05; % 5% noise level
    
    % Create a copy of the sample
    augSample = sample;
    
    % Get all field names
    fieldNames = fieldnames(sample);
    for i = 1:length(fieldNames)
        fieldName = fieldNames{i};
        fieldValue = sample.(fieldName);
        
        % Skip non-numeric fields and any field names with ROI in them
        if ~isnumeric(fieldValue) || contains(fieldName, 'ROI')
            continue;
        end
        
        % Add noise based on the range of values
        valueRange = max(fieldValue) - min(fieldValue);
        noiseLevel = valueRange * noiseFactor;
        
        % Add random noise
        noise = noiseLevel * (rand(size(fieldValue)) - 0.5);
        augSample.(fieldName) = fieldValue + noise;
    end
end