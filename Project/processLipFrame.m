function [lipMask, lipFeatures] = processLipFrame(frame)
    % Process frame to extract lip region
    
    % Convert to YCbCr color space
    img = rgb2ycbcr(frame);
    [~, cb, cr] = imsplit(img);
    
    % Apply thresholds for lip detection
    cb_thresh = cb < 114;
    cr_thresh = cr > 166;
    
    % Process mask
    cr_lim = bwareafilt(cr_thresh, 1);
    lips = cb_thresh & cr_lim;
    
    % Clean up mask
    lips = imclose(lips, strel('disk', 4));
    lipMask = imclose(lips, strel('disk', 10));
    
    % Extract features
    stats = regionprops(lipMask, 'BoundingBox', 'Centroid', 'Area');
    
    % Initialize result
    lipFeatures = struct('LipFound', false);
    
    % If lips found, extract features
    if ~isempty(stats)
        % Find largest region
        if length(stats) > 1
            areas = [stats.Area];
            [~, idx] = max(areas);
            stats = stats(idx);
        end
        
        % Extract features
        lipFeatures.LipFound = true;
        lipFeatures.BoundingBox = stats.BoundingBox;
        lipFeatures.Centroid = stats.Centroid;
        lipFeatures.Area = stats.Area;
    end
end