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
