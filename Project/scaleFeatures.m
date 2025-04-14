function augSample = scaleFeatures(sample)
    % Scale features up or down slightly
    scaleFactor = 0.9 + 0.2 * rand(); % Random factor between 0.9 and 1.1
    
    % Create a copy of the sample
    augSample = sample;
    
    % Fields to scale
    scaleFields = {'area', 'width', 'height'};
    
    % Scale selected fields
    for i = 1:length(scaleFields)
        fieldName = scaleFields{i};
        
        if isfield(sample, fieldName)
            augSample.(fieldName) = sample.(fieldName) * scaleFactor;
        end
    end
    
    % Update related fields
    if isfield(augSample, 'width') && isfield(augSample, 'height')
        augSample.aspectRatio = augSample.width ./ augSample.height;
        augSample.lipRatio = augSample.height ./ augSample.width;
    end
end