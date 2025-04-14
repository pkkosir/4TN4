function showFeatureImportance(model)
    % Visualize feature importance for the trained model
    % This works if the model is a tree-based model
    
    try
        % Check if model is a tree-based model with feature importance
        if isfield(model, 'modelObj') && ...
                (isa(model.modelObj, 'ClassificationEnsemble') || isa(model.modelObj, 'ClassificationTree'))
            
            % Get feature importance
            if isa(model.modelObj, 'ClassificationEnsemble')
                imp = predictorImportance(model.modelObj);
            else
                imp = predictorImportance(model.modelObj);
            end
            
            % Feature names
            featureNames = {'Mean Lip Ratio', 'Std Lip Ratio', 'Mean Area', 'Area Variation', ...
                'Centroid Movement', 'Lip Ratio Range', 'Area Ratio'};
            
            % Create figure
            figure('Name', 'Feature Importance', 'Position', [200, 200, 800, 500]);
            
            % Sort features by importance
            [sortedImp, idx] = sort(imp, 'descend');
            sortedNames = featureNames(idx);
            
            % Plot as horizontal bar chart
            barh(sortedImp);
            set(gca, 'YTick', 1:length(featureNames), 'YTickLabel', sortedNames);
            title('Feature Importance for Lip Reading');
            xlabel('Importance');
            ylabel('Feature');
            grid on;
            
            % Add values at the end of each bar
            for i = 1:length(sortedImp)
                text(sortedImp(i), i, sprintf(' %.3f', sortedImp(i)), 'VerticalAlignment', 'middle');
            end
        else
            warning('Model does not support feature importance visualization');
        end
    catch e
        warning('Could not visualize feature importance: %s', e.message);
    end
end