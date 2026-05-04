%% Input Params
MHs={'Ada','Garry','Cooper','Pia'};
gender_id={'w','m','m','w'};
m_ind=find(strcmp(gender_id,'m'));
w_ind=find(strcmp(gender_id,'w'));
animations={'AU01','AU02','AU04','AU06','AU07','AU10' ...
            'AU12','AU14','AU15','AU17','AU23','browsAll'...
            'browsAU10','browsAU12','browsAU14','browsAU15','browsAU17','browsAU23'};
AUs_only_anim=animations(1:end-7);
main_path=['C:\Users\hilal\Desktop\JLU-Dobs\MetaHumanRecordings\_UnrealEngine_Animations\Analyses\'];
cd([main_path 'Inverse_affine_transform\corr_bw_avatars_across_anim\'])

load([main_path 'UE5_Python\anim_data.mat'])

%% Cross-correlation
for id=1:length(MHs)
    curID=MHs{id};
    corr_at_lag_0_OF_arr=[]; corr_at_lag_0_AFAR_arr=[]; corr_at_lag_0_OFvsAFAR_arr=[];
    for anim=1:length(animations)
        curAnim=animations{anim};
        actual_mat=anim_data.(curID).(['anim_' curAnim]).actual;
        AFAR_pred=anim_data.(curID).(['anim_' curAnim]).AFAR;
        OF_pred=anim_data.(curID).(['anim_' curAnim]).OF;
        pyFeat_pred=anim_data.(curID).(['anim_' curAnim]).pyFeat;

        figure; subplot(1,4,1); imagesc(actual_mat'); 
        colorbar; caxis([0 1]); title('Actual Data');
        yticklabels(AUs_only_anim)
        subplot(1,4,2); imagesc(OF_pred'); colorbar; caxis([0 1]);
        title('OpenFace Prediction'); yticklabels(AUs_only_anim)
        subplot(1,4,3); imagesc(AFAR_pred'); colorbar; caxis([0 1]); 
        title('AFAR Prediction'); yticklabels(AUs_only_anim)
        subplot(1,4,4); imagesc(pyFeat_pred'); colorbar; caxis([0 1]); 
        title('pyFeat Prediction'); yticklabels(AUs_only_anim)
        
        % Cross-correlation: Actual vs OF
        [c, lags] = xcorr(diff(actual_mat(:)), diff(OF_pred(:)), 'coeff');  
        
        % I am taking the diff(x) in order to make my time series stationary. 
        % In its nature, my original data is not stationary because it has certain trends and seasonality
        % I applied ADF to check for stationarity on python: ADF_test_to_check_stationary_time_series.ipynb
        % 'coeff' normalizes the correlation values
        cross_corr_results.(curID)(anim).actual_OF=c(find(lags==0));
        corr_at_lag_0_OF=c(find(lags==0));
        corr_at_lag_0_OF_arr=[corr_at_lag_0_OF_arr corr_at_lag_0_OF];
                
        % Actual vs AFAR
        [c, lags] = xcorr(diff(actual_mat(:)), diff(AFAR_pred(:)), 'coeff');  
        cross_corr_results.(curID)(anim).actual_AFAR=c(find(lags==0));
        corr_at_lag_0_AFAR=c(find(lags==0));
        corr_at_lag_0_AFAR_arr=[corr_at_lag_0_AFAR_arr corr_at_lag_0_AFAR];

        % % Actual vs pyFeat
        % [c, lags] = xcorr(diff(actual_mat(:)), diff(pyFeat_pred(:)), 'coeff');  
        % cross_corr_results.(curID)(anim).actual_pyFeat=c(find(lags==0));
        
        % OF vs AFAR
        [c, lags] = xcorr(diff(OF_pred(:)), diff(AFAR_pred(:)), 'coeff');  
        cross_corr_results.(curID)(anim).OF_AFAR=c(find(lags==0));
        corr_at_lag_0_OFvsAFAR=c(find(lags==0));
        corr_at_lag_0_OFvsAFAR_arr=[corr_at_lag_0_OFvsAFAR_arr corr_at_lag_0_OFvsAFAR];

    end
    cross_corr_results.(curID)(anim).corr_at_lag_0_OF=corr_at_lag_0_OF_arr;
    cross_corr_results.(curID)(anim).corr_at_lag_0_AFAR=corr_at_lag_0_AFAR_arr;
    cross_corr_results.(curID)(anim).corr_at_lag_0_OFvsAFAR=corr_at_lag_0_OFvsAFAR_arr;

    close all;
end
save cross_corr_results_upd cross_corr_results

%% Calculate the mean pairwise correlation
corr_coef_all=[];
for exp=1:length(animations)
    corr_coef=normed_corr_bw_avatars(exp).corrcoef(:);
    corr_coef_all=[corr_coef_all,corr_coef];
    corr_coef=[];
end
mean_corr_coef=mean(corr_coef_all');
corr_coef_mean_mat=[mean_corr_coef(1:4);mean_corr_coef(5:8);mean_corr_coef(9:12);mean_corr_coef(13:16)];
corr_fig=figure; heatmap(MHs, MHs, corr_coef_mean_mat); colormap(parula);
colorbar; caxis([0 1]); title(['Mean Pairwise-Correlation']);
save_fig_name=['Heatmap_mean_pairw_corr.fig'];
saveas(corr_fig, save_fig_name);

%% DETAILS REGARDING TIME-SERIES ANALYSES:
% %% Cross Correlation Analysis
% series1=actual_mat(:);
% series2=OF_pred(:);
% [c, lags] = xcorr(diff(series1), diff(series2), 'coeff');  
% % I am taking the diff(x) in order to make my time series stationary. 
% % In its nature, my original data is not stationary because it has certain trends and seasonality
% % I applied ADF to check for stationarity on python: ADF_test_to_check_stationary_time_series.ipynb
% % 'coeff' normalizes the correlation values
% 
% % Number of observations
% N = length(series1);
% 
% % Calculate significance bounds
% conf_bound = 2 / sqrt(N);
% 
% % Plot
% figure;
% stem(lags, c, 'filled');
% hold on;
% plot([lags(1) lags(end)], [conf_bound conf_bound], 'r--', 'LineWidth', 1.5);  % Upper bound
% plot([lags(1) lags(end)], [-conf_bound -conf_bound], 'r--', 'LineWidth', 1.5);  % Lower bound
% hold off;
% xlabel('Lag');
% ylabel('Cross-Correlation');
% title('Cross-Correlation between Series1 and Series2');
% legend('Cross-Correlation', 'Confidence Bound');

% %% Apply Dynamic Time Warping
% [dist, ix, iy] = dtw(series1, series2);
% 
% % Plot DTW alignment
% figure;
% plot(ix, iy);
% title('Dynamic Time Warping Alignment');
% xlabel('Index of Series 1');
% ylabel('Index of Series 2');
% disp(['DTW distance: ', num2str(dist)]);
% 
% %% Significance test for DTW
% % Number of permutations
% nPermutations = 1000;
% 
% % Original DTW distance
% original_dist = dist;
% 
% % Initialize array to store permuted DTW distances
% perm_dists = zeros(nPermutations, 1);
% 
% % Permutation test
% for i = 1:nPermutations
%     % Randomly permute one of the series
%     perm_series2 = series2(randperm(length(series2)));
% 
%     % Compute DTW distance with permuted series
%     [perm_dist, ~, ~] = dtw(series1, perm_series2);
% 
%     % Store the permuted DTW distance
%     perm_dists(i) = perm_dist;
% end
% 
% % Compute p-value
% pValue = sum(perm_dists >= original_dist) / nPermutations;
% 
% % Display results
% fprintf('Original DTW distance: %f\n', original_dist);
% fprintf('P-value: %f\n', pValue);
% 
% % Plot histogram of permuted DTW distances
% figure;
% histogram(perm_dists, 30);
% hold on;
% yLimits = ylim;
% plot([original_dist original_dist], yLimits, 'r--', 'LineWidth', 2);
% title('Permutation Test for DTW Distance');
% xlabel('DTW Distance');
% ylabel('Frequency');
% legend('Permuted Distances', 'Original Distance');

