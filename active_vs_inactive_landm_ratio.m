%% Load data and input parameters
MHs={'Ada','Garry','Cooper','Pia'};
animations={'AU01','AU02','AU04','AU06','AU07','AU10' ...
            'AU12','AU14','AU15','AU17','AU23','browsAll'...
            'browsAU10','browsAU12','browsAU14','browsAU15','browsAU17','browsAU23'};
AUs_only_anim=animations(1:end-7);
path='C:\Users\hilal\Desktop\JLU-Dobs\MetaHumanRecordings\_UnrealEngine_Animations\Analyses\Inverse_affine_transform\';
load([path 'peak_frame_classification\motion_params.mat'])
load([path 'AU_landm_mapping.mat'])

%% 
for av=1:length(MHs)
    for anim=1:length(animations)
        landm_data=motion_params(av).videos(anim).coord_eucl_dif';
        mean_scaled_data=landm_data/mean(landm_data(:));
        landm_all_idx=[1:size(mean_scaled_data,1)];
        landm_target_idx=AU_landm_mapping{anim,3};
        landm_other_idx=setdiff(landm_all_idx,landm_target_idx);

        target_landm_data=mean_scaled_data(landm_target_idx,:);
        other_landm_data=mean_scaled_data(landm_other_idx,:);
        output.actv_landm_displ_data(av).(animations{anim})=target_landm_data;
        output.inactv_landm_displ_data(av).(animations{anim})=other_landm_data;
        if anim < 12
            peak_target=target_landm_data(:,30);
            peak_other=other_landm_data(:,30);
            output.peak_actv_landm_displ_data(av).(animations{anim})=peak_target;
            output.peak_inactv_landm_displ_data(av).(animations{anim})=peak_other;
            output.mean_peak_actv_landm_displ_data(av).(animations{anim})=mean(peak_target(:));
            output.mean_peak_inactv_landm_displ_data(av).(animations{anim})=mean(peak_other(:));
            peak_target=[]; peak_other=[];
        else
            pk_idx=[15,30,45]; peak_target=target_landm_data(:,pk_idx);
            peak_other=other_landm_data(:,pk_idx);
            output.peak_actv_landm_displ_data(av).(animations{anim})=peak_target;
            output.peak_inactv_landm_displ_data(av).(animations{anim})=peak_other;
            output.mean_peak_actv_landm_displ_data(av).(animations{anim})=mean(peak_target(:));
            output.mean_peak_inactv_landm_displ_data(av).(animations{anim})=mean(peak_other(:));
            peak_target=[]; peak_other=[];
        end
        output.mean_actv_landm_displ(av).(animations{anim})=mean(target_landm_data(:));
        output.mean_inactv_landm_displ(av).(animations{anim})=mean(other_landm_data(:));
        active_inactive_perc_r=mean(target_landm_data(:))/mean(other_landm_data(:))*100;
        output.act_inactv_perc_ratio(av).(animations{anim})=active_inactive_perc_r;
        perc_r=mean(target_landm_data(:))/mean(landm_data(:))*100;
        output.percent_ratio(av).(animations{anim})=perc_r;
        perc_r=[]; active_inactive_r=[];  
    end
end
save output output
%% save struct as a csv
writetable(struct2table(output.actv_landm_displ_data), 'actv_landm_data.csv')
writetable(struct2table(output.inactv_landm_displ_data), 'inactv_landm_data.csv')
writetable(struct2table(output.peak_actv_landm_displ_data), 'peak_actv_landm_displ_data.csv')
writetable(struct2table(output.peak_inactv_landm_displ_data), 'peak_inactv_landm_displ_data.csv')
writetable(struct2table(output.mean_peak_actv_landm_displ_data), 'mean_peak_actv_landm_displ_data.csv')
writetable(struct2table(output.mean_peak_inactv_landm_displ_data), 'mean_peak_inactv_landm_displ_data.csv')
writetable(struct2table(output.mean_actv_landm_displ), 'mean_actv_landm_displ.csv')
writetable(struct2table(output.mean_inactv_landm_displ), 'mean_inactv_landm_displ.csv')
writetable(struct2table(output.act_inactv_perc_ratio), 'act_inactv_percentage_landm_ratio.csv')
writetable(struct2table(output.percent_ratio), 'landm_mean_displacement_percent_ratio.csv')