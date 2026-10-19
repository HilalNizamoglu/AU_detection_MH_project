main_path='C:\Users\hilal\Desktop\JLU-Dobs\MetaHuman Recordings\UnrealEngine_Animations';
out_path= 'C:\Users\hilal\Desktop\JLU-Dobs\MetaHuman Recordings\UnrealEngine_Animations\UE5_Python';

MHs={'Ada','Garry','Cooper','Pia'};
animations={'AU01','AU02','AU04','AU06','AU07','AU10' ...
            'AU12','AU14','AU15','AU17','AU23','browsAll'...
            'browsAU10','browsAU12','browsAU14','browsAU15','browsAU17','browsAU23'};
AUs_only_anim=animations(1:end-7);
for id = 1:length(MHs)
    AU_comb_col_start=6; %For the AU comb anims after browsAll, write actual values to 
    % the relevant AU columns (i.e. browsAU10 --> actual_val cols: 1,2,3,6; 
    % browsAU12 --> actual_val cols: 1,2,3,7; ...; browsAU17 --> actual_val cols:1,2,3,10)
    for anim = 1:length(animations)
        load([main_path '/' MHs{id} '_' animations{anim} '_OFvsAFAR_output/' MHs{id} '_' animations{anim} '_OFvsAFAR_output.mat'])
        close all
        struct_name=['anim_' animations{anim}];
        cd(out_path)
        csv_mat=csvread([MHs{id} '_rigValues_anim_' animations{anim} '.csv'], 1,0);
        if anim <= length(AUs_only_anim)
            actual_val=csv_mat(:,1);
            actual_mat=zeros(size(actual_val,1),length(AUs_only_anim));
            actual_mat(:,anim)=actual_val;
            anim_data.(MHs{id}).(struct_name).actual=actual_mat;
        else %AUcomb animations
            actual_mat=zeros(size(csv_mat,1),length(AUs_only_anim));
            actual_mat(:,1)= csv_mat(:,1); %AU01
            actual_mat(:,2)= csv_mat(:,3); %AU02
            actual_mat(:,3)= csv_mat(:,5); %AU04
            if size(csv_mat,2) > 6 %other than browsAll
                actual_mat(:,AU_comb_col_start)= csv_mat(:,7); %AU10,12,14,15,17,23
                AU_comb_col_start=AU_comb_col_start+1;
            end
            anim_data.(MHs{id}).(struct_name).actual=actual_mat;
        end
        normed_OF_pred=output.overlapping_OFdata/5;
        anim_data.(MHs{id}).(struct_name).OF=normed_OF_pred;
        AFAR_pred=output.overlapping_AFARdata;
        anim_data.(MHs{id}).(struct_name).AFAR=AFAR_pred;
        savename_actual=[MHs{id} '_actualValues_anim_' animations{anim} '.mat'];
        save(savename_actual, "actual_mat")
        savename_OF=[MHs{id} '_OFpred_anim_' animations{anim} '.mat'];
        save(savename_OF, "normed_OF_pred")
        savename_AFAR=[MHs{id} '_AFARpred_anim_' animations{anim} '.mat'];
        save(savename_AFAR, "AFAR_pred")
        
    end
    save anim_data anim_data 
end