main_path=['C:\Users\hilal\Desktop\JLU-Dobs\MetaHuman Recordings\_UnrealEngine_Animations\Analyses\'];
cd([main_path 'Inverse_affine_transform\corr_bw_avatars_across_anim\'])
MHs={'Ada','Garry','Cooper','Pia'};
gender_id={'w','m','m','w'};
m_ind=find(strcmp(gender_id,'m'));
w_ind=find(strcmp(gender_id,'w'));
animations={'AU01','AU02','AU04','AU06','AU07','AU10' ...
            'AU12','AU14','AU15','AU17','AU23','browsAll'...
            'browsAU10','browsAU12','browsAU14','browsAU15','browsAU17','browsAU23'};
AUs_only_anim=animations(1:end-7);
load([main_path 'Inverse_affine_transform\peak_frame_classification\motion_params.mat'])
%% Correlation bw avatars across different animations
for exp=1:length(animations)
    curExp=animations{exp};
    corr_landm_fr=corrcoef([motion_params(1).videos(exp).coord_eucl_dif(:),...
        motion_params(2).videos(exp).coord_eucl_dif(:), ...
        motion_params(3).videos(exp).coord_eucl_dif(:), ...
        motion_params(4).videos(exp).coord_eucl_dif(:)]);
    corr_fig=figure; imagesc(corr_landm_fr); colorbar; caxis([0 1]); xticks(1:4);
    xticklabels(MHs); yticks(1:4); yticklabels(MHs); 
    title(['Correlation bw avatars: ' curExp]);
    save_fig_name=['Corr_bw_avatars_' curExp '.fig'];
    %saveas(corr_fig, save_fig_name);
    close all;
    corr_bw_avatars(exp).curAnim=curExp;
    corr_bw_avatars(exp).corrcoef=corr_landm_fr;
    corr_bw_avatars(exp).corrcoef_mean=mean(corr_landm_fr(find(triu(corr_landm_fr,1)>0)));
    corr_bw_avatars(exp).corrcoef_min=min(corr_landm_fr(:));
    corr_landm_fr=[];
end
%save corr_bw_avatars corr_bw_avatars
%% Mean scaled data
for exp=1:length(animations)
    curExp=animations{exp};
    corr_landm_fr=corrcoef([motion_params(1).videos(exp).coord_eucl_dif(:)/mean(motion_params(1).videos(exp).coord_eucl_dif(:)),...
        motion_params(2).videos(exp).coord_eucl_dif(:)/mean(motion_params(2).videos(exp).coord_eucl_dif(:)), ...
        motion_params(3).videos(exp).coord_eucl_dif(:)/mean(motion_params(3).videos(exp).coord_eucl_dif(:)), ...
        motion_params(4).videos(exp).coord_eucl_dif(:)/mean(motion_params(4).videos(exp).coord_eucl_dif(:))]);
    corr_fig=figure; imagesc(corr_landm_fr); colorbar; caxis([0 1]); xticks(1:4);
    xticklabels(MHs); yticks(1:4); yticklabels(MHs); 
    title(['Correlation bw avatars: ' curExp]);
    save_fig_name=['Mean_scaled_Corr_bw_avatars_' curExp '.fig'];
    %saveas(corr_fig, save_fig_name);
    close all;
    mean_scaled_corr_bw_avatars(exp).curAnim=curExp;
    mean_scaled_corr_bw_avatars(exp).corrcoef=corr_landm_fr;
    mean_scaled_corr_bw_avatars(exp).corrcoef_mean=mean(corr_landm_fr(find(triu(corr_landm_fr,1)>0)));
    mean_scaled_corr_bw_avatars(exp).corrcoef_min=min(corr_landm_fr(:));
    corr_landm_fr=[];
end
save mean_scaled_corr_bw_avatars mean_scaled_corr_bw_avatars
%% Find the low correlation animations
load('corr_bw_avatars.mat')
count=1;
for i=1:length(corr_bw_avatars)
    if corr_bw_avatars(i).corrcoef_min < 0.7
        low_corr_Anim{count}=animations{i};
        count=count+1;
    end
end
%% Check the imagesc of motion_params(all).videos(mean_low_corr_exp).coord_eucl_dif
for i=1:length(low_corr_Anim)
    for id=1:length(MHs)
        anim_idx=find(strcmp(low_corr_Anim{i},animations));
        low_corr_coord_dif(:,:,id)=motion_params(id).videos(anim_idx).coord_eucl_dif'; %landm x fr x avatar
    end
    landm_fr_fig=figure; 
    subplot(4,1,1); imagesc(low_corr_coord_dif(:,:,1)); 
    colorbar; caxis([0 max(low_corr_coord_dif(:))]); title(MHs{1});
    subplot(4,1,2); imagesc(low_corr_coord_dif(:,:,2)); 
    colorbar; caxis([0 max(low_corr_coord_dif(:))]); title(MHs{2});
    subplot(4,1,3); imagesc(low_corr_coord_dif(:,:,3)); 
    colorbar; caxis([0 max(low_corr_coord_dif(:))]); title(MHs{3});
    subplot(4,1,4); imagesc(low_corr_coord_dif(:,:,4)); 
    colorbar; caxis([0 max(low_corr_coord_dif(:))]); title(MHs{4});
    suptitle(['51 landm x frames: ' animations{anim_idx} ' corrl mean: ' num2str(corr_bw_avatars(anim_idx).corrcoef_mean,'%.2f')])
    save_fig_name=['lowly_corrl_animations_' animations{anim_idx} '.fig'];
    saveas(landm_fr_fig, save_fig_name);
end

%% Run drawLandmarks.m for the animation types with low corrcoef mean
load('C:\Users\hilal\Desktop\JLU-Dobs\MetaHuman Recordings\_UnrealEngine_Animations\Analyses\Inverse_affine_transform\OFresults.mat')
for i=1:length(low_corr_Anim)
    anim_idx=find(strcmp(low_corr_Anim{i},animations));
    for id=1:length(MHs)
        figure; title([MHs{id} ' : ' animations{anim_idx}])
        v = VideoWriter([MHs{id} '_' animations{anim_idx} 'landmark_animation.avi']); 
        v.FrameRate=15; open(v)
        xlabel('X');
        ylabel('Y');
        zlabel('Z');
        title('Trajectory of Points in 3D Space over Time');
        grid on;
    
        corrData_x_arr=[]; corrData_y_arr=[]; corrData_z_arr=[];
        for k = 1:60
            corrData_x_arr=[corrData_x_arr; OFresults(id).landmarks(anim_idx).frames(k).corrected_marker(1,:)];
            corrData_y_arr=[corrData_y_arr; OFresults(id).landmarks(anim_idx).frames(k).corrected_marker(2,:)];
            corrData_z_arr=[corrData_z_arr; OFresults(id).landmarks(anim_idx).frames(k).corrected_marker(3,:)];
        end
        scatter_plot = scatter3(OFresults(id).landmarks(anim_idx).frames(1).corrected_marker(1,:), [OFresults(id).landmarks(anim_idx).frames(1).corrected_marker(2,:)*(-1)], OFresults(id).landmarks(anim_idx).frames(1).corrected_marker(3,:));
        xlim([min(corrData_x_arr(:)), max(corrData_x_arr(:))]);
        ylim([max(corrData_y_arr(:))*(-1), min(corrData_y_arr(:))*(-1)]);
        zlim([min(corrData_z_arr(:)), max(corrData_z_arr(:))]);
        %view(0,90); %viewing the x and y axes
        view(-153,-78)
        hold on;
    
        % Iterate over each frame and update the scatter plot
        for fr = 1:60
            % Update scatter plot with new frame of data
            set(scatter_plot, ...
                'XData', OFresults(id).landmarks(anim_idx).frames(fr).corrected_marker(1,:), ...
                'YData', [OFresults(id).landmarks(anim_idx).frames(fr).corrected_marker(2,:)*(-1)], ...
                'ZData', OFresults(id).landmarks(anim_idx).frames(fr).corrected_marker(3,:));
            xlim([min(corrData_x_arr(:)), max(corrData_x_arr(:))]);
            ylim([max(corrData_y_arr(:))*(-1), min(corrData_y_arr(:))*(-1)]);
            zlim([min(corrData_z_arr(:)), max(corrData_z_arr(:))]);
            drawnow;
            pause(0.1); % Adjust the pause duration as needed for desired animation speed
            frame = getframe;
            writeVideo(v,frame)
        end
        close(v)
    end
end

%% Correlation bw normed_eucl_coord_dif
for exp=1:length(animations)
    curExp=animations{exp};
    normed_corr_landm_fr=corrcoef([motion_params(1).videos(exp).normed_coord_eucl_dif_mat(:),...
        motion_params(2).videos(exp).normed_coord_eucl_dif_mat(:), ...
        motion_params(3).videos(exp).normed_coord_eucl_dif_mat(:), ...
        motion_params(4).videos(exp).normed_coord_eucl_dif_mat(:)]);
    corr_fig=figure; %imagesc(normed_corr_landm_fr); 
    heatmap(MHs, MHs, normed_corr_landm_fr); colormap(parula);
    colorbar; caxis([0 1]); %xticks(1:4);
    %xticklabels(MHs); yticks(1:4); yticklabels(MHs); 
    title(['Correlation bw avatars: ' curExp]);
    save_fig_name=['Heatmap_normed_Corr_bw_avatars_' curExp '.fig'];
    saveas(corr_fig, save_fig_name);
    close all;
    normed_corr_bw_avatars(exp).curAnim=curExp;
    normed_corr_bw_avatars(exp).corrcoef=normed_corr_landm_fr;
    normed_corr_bw_avatars(exp).corrcoef_mean=mean(normed_corr_landm_fr(find(triu(normed_corr_landm_fr,1)>0)));
    normed_corr_bw_avatars(exp).corrcoef_min=min(normed_corr_landm_fr(:));
    normed_corr_landm_fr=[];
end
save normed_corr_bw_avatars normed_corr_bw_avatars
% I then saved the corr values as a table on google sheets via ...
% i=1:18; 
% normed_corr_bw_avatars(i).corrcoef(find(triu(normed_corr_bw_avatars(i).corrcoef,1)~=0))'
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
%% Plot bargraph of animations across avatars
corr_anim_all=[]; corr_coef_anim_all=[];
for exp=1:length(animations)
    curExp=animations{exp};
    corr_landm_fr=corrcoef([motion_params(1).videos(exp).coord_eucl_dif(:),...
        motion_params(2).videos(exp).coord_eucl_dif(:), ...
        motion_params(3).videos(exp).coord_eucl_dif(:), ...
        motion_params(4).videos(exp).coord_eucl_dif(:)]);
    corr_anim=corr_landm_fr(find(triu(corr_landm_fr,1)>0));
    corr_anim_all=[corr_anim_all corr_anim];
    SEM_anim(exp)=std(corr_anim)/sqrt(length(corr_anim)); corr_anim=[];
    corr_coef=normed_corr_bw_avatars(exp).corrcoef_mean;
    corr_coef_anim_all=[corr_coef_anim_all,corr_coef];
    corr_coef=[];
end
err_low=SEM_anim*1.96;
err_high=SEM_anim*1.96;
corr_bar=figure; bar(corr_coef_anim_all); xticks(1:18)
xticklabels(animations); ylabel('Correlation Coefficient')
hold on
er = errorbar([1:18],corr_coef_anim_all,err_low,err_high);    
er.Color = [0 0 0];                            
er.LineStyle = 'none'; 
hold off
%% Find the low correlation animations
%load('normed_corr_bw_avatars.mat')
count=1;
for i=1:length(normed_corr_bw_avatars)
    if normed_corr_bw_avatars(i).corrcoef_min < 0.7
        low_corr_Anim{count}=animations{i};
        count=count+1;
    end
end
%% Check the imagesc of motion_params(all).videos(mean_low_corr_exp).coord_eucl_dif
for i=1:length(low_corr_Anim)
    for id=1:length(MHs)
        anim_idx=find(strcmp(low_corr_Anim{i},animations));
        low_corr_coord_dif(:,:,id)=motion_params(id).videos(anim_idx).normed_coord_eucl_dif_mat; %landm x fr x avatar
    end
    landm_fr_fig=figure; 
    subplot(4,1,1); imagesc(low_corr_coord_dif(:,:,1)); 
    colorbar; caxis([0 max(low_corr_coord_dif(:))]); title(MHs{1});
    subplot(4,1,2); imagesc(low_corr_coord_dif(:,:,2)); 
    colorbar; caxis([0 max(low_corr_coord_dif(:))]); title(MHs{2});
    subplot(4,1,3); imagesc(low_corr_coord_dif(:,:,3)); 
    colorbar; caxis([0 max(low_corr_coord_dif(:))]); title(MHs{3});
    subplot(4,1,4); imagesc(low_corr_coord_dif(:,:,4)); 
    colorbar; caxis([0 max(low_corr_coord_dif(:))]); title(MHs{4});
    suptitle(['51 landm x frames: ' animations{anim_idx} ' corrl mean: ' num2str(corr_bw_avatars(anim_idx).corrcoef_mean,'%.2f')])
    save_fig_name=['normed_lowly_corrl_animations_' animations{anim_idx} '.fig'];
    saveas(landm_fr_fig, save_fig_name);
end