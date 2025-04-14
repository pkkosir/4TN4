function augSample = jitterPosition(sample)
    % Add small jitter to position-related features
    jitterFactor = 0.1; % 10% jitter level
    
    % Create a copy of the sample
    augSample = sample;
    
    % Jitter centroid positions
    if isfield(sample, 'centroidX') && isfield(sample, 'centroidY')
        % Calculate jitter amount
        xRange = max(sample.centroidX) - min(sample.centroidX);
        yRange = max(sample.centroidY) - min(sample.centroidY);
        
        xJitter = xRange * jitterFactor * (rand(size(sample.centroidX)) - 0.5);
        yJitter = yRange * jitterFactor * (rand(size(sample.centroidY)) - 0.5);
        
        % Apply jitter
        augSample.centroidX = sample.centroidX + xJitter;
        augSample.centroidY = sample.centroidY + yJitter;
    end
end