function augSample = dropFrames(sample)
    % Randomly drop a small percentage of frames
    dropRate = 0.1; % Drop 10% of frames
    
    % Create a copy of the sample
    augSample = struct();
    
    % Get all field names
    fieldNames = fieldnames(sample);
    
    % Get time series length (assuming all fields have the same length)
    for i = 1:length(fieldNames)
        fieldName = fieldNames{i};
        fieldValue = sample.(fieldName);
        
        if isnumeric(fieldValue) && ~isscalar(fieldValue)
            tsLength = length(fieldValue);
            break;
        end
    end
    
    % Create random mask for frames to keep
    keepMask = rand(tsLength, 1) > dropRate;
    
    % Ensure we keep at least 80% of the frames
    minKeep = ceil(0.8 * tsLength);
    if sum(keepMask) < minKeep
        % Not enough frames kept, regenerate mask
        keepIdx = randperm(tsLength, minKeep);
        keepMask = false(tsLength, 1);
        keepMask(keepIdx) = true;
    end
    
    % Apply mask to all time series fields
    for i = 1:length(fieldNames)
        fieldName = fieldNames{i};
        fieldValue = sample.(fieldName);
        
        if isnumeric(fieldValue) && length(fieldValue) == tsLength
            % This is a time series field, apply the mask
            augSample.(fieldName) = fieldValue(keepMask);
        elseif iscell(fieldValue) && length(fieldValue) == tsLength
            % This is a cell array time series field
            augSample.(fieldName) = fieldValue(keepMask);
        else
            % Copy the field as is
            augSample.(fieldName) = fieldValue;
        end
    end
end
