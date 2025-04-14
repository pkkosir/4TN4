function augSample = timeStretch(sample)
    % Time stretching: Slightly speed up or slow down the sequence
    stretchFactor = 0.8 + 0.4 * rand(); % Random factor between 0.8 and 1.2
    
    % Create a copy of the sample
    augSample = sample;
    
    % Get all field names that are time series
    fieldNames = fieldnames(sample);
    for i = 1:length(fieldNames)
        fieldName = fieldNames{i};
        fieldValue = sample.(fieldName);
        
        % Skip non-numeric fields and any field names with ROI in them
        if ~isnumeric(fieldValue) || contains(fieldName, 'ROI')
            continue;
        end
        
        % Get length of time series
        tsLength = length(fieldValue);
        
        % New time points
        oldTimePoints = 1:tsLength;
        newTimePoints = 1:stretchFactor:tsLength;
        
        % Interpolate to get new values
        if length(newTimePoints) > 1
            augSample.(fieldName) = interp1(oldTimePoints, fieldValue, newTimePoints, 'linear', 'extrap');
        end
    end
end