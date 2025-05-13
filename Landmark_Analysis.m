%% LANDMARK ANALYSIS ON MH ANIMATION
% path=['C:\Users\hilal\Desktop\JLU-Dobs\MetaHuman Recordings\UnrealEngine_Animations\'];
% id={'Ada','Garry'};
% AU_names={'AU01','AU02','AU04','AU06','AU07','AU10','AU12','AU14','AU15',...
%     'AU17','AU23','browsAll','browsAU10','browsAU12','browsAU14','browsAU15','browsAU17','browsAU23'};

%% LANDMARK ANALYSIS ON MPI DATABASE
path=['C:\Users\hilal\Desktop\JLU-Dobs\MPI_large_database'];
cd(path)
id={'mamm','silf','cawm','chsm','islf','jakm','juhm','kabf','lekf','milf'};
load('expressions_list.mat')
expressions=unique(expressions_list);

%% Plotting bar graphs
for ID_count=1:length(id)
    curID=id{ID_count};
    for AU_count=1:length(expressions) %length(AU_names)
        %curAU=AU_names{AU_count};
        curAU=expressions{AU_count};
        %cd([path curID '\OpenFace_output'])
%       fname=[curID '_' curAU '_OF-results.mat'];
%       load(fname)

        cd([path '\OF_output'])
        csv_fname= [curID '_' curAU '.csv'];
        OF_out= readtable(csv_fname);
        OFresults.table=OF_out;
        
        % LANDMARKS=[x ; y] --> L(:,i) : ith landmark's coordinates
        landmark_col.eyebrows=[317:326; 385:394]; % 17:26; 10 Ls; table column numbers for eyebrow landmarks
        landmark_col.eyes=[336:347; 404:415]; % 36:47; 12 Ls; table column numbers for eye landmarks
        landmark_col.nose=[327:335; 395:403]; % 27:35; 9 Ls; table column numbers for nose landmarks
        landmark_col.mouth=[348:367; 416:435]; % 48:67; 20 Ls; table column numbers for mouth landmarks

        x = linspace(1,size(OFresults.table,1),size(OFresults.table,1)); % creating linspace for plotting


        landmark_eyebrows=OFresults.table(:,landmark_col.eyebrows); landmark_eyebrows=table2array(landmark_eyebrows); % 75 x20: 75 frames by 10 (x,y)s: landmark_eyebrows(frames,2n-1:2n+1) 
        landmark_eyes=OFresults.table(:,landmark_col.eyes); landmark_eyes=table2array(landmark_eyes);
        landmark_mouth=OFresults.table(:,landmark_col.mouth); landmark_mouth=table2array(landmark_mouth);
        landmark_nose=OFresults.table(:,landmark_col.nose); landmark_nose=table2array(landmark_nose);
        
        %cd ([path '\' curID '_' curAU '_OFvsAFAR_output\'])
        cd ([path '\landmark_results'])
        
        % Plotting eyebrow landmarks
%         fig_EB=figure(1);
%         for n=1:length(landmark_col.eyebrows) %10 iteration
%             EB(n).temp=landmark_eyebrows(:,2*n-1:2*n);
%             subplot(length(landmark_col.eyebrows),1,n)
%             for k=2:length(EB(n).temp)
%                 EB(n).x_dif(k-1)=EB(n).temp(k,1)-EB(n).temp(k-1,1);
%                 EB(n).y_dif(k-1)=EB(n).temp(k,2)-EB(n).temp(k-1,2);
%                 EB(n).temp_dif(k-1)=sqrt(EB(n).x_dif(k-1).^2 + EB(n).y_dif(k-1).^2);
%             end
%             bar(EB(n).temp_dif)
%             ylim([0 1])
%             legend(['Eyebrow Landmark:' num2str(n)],'Location','westoutside',...
%                         'Orientation','horizontal');
%         end
%             save_fig_name=[curID '_' curAU '_LandmarkEyebrows.fig'];
%             saveas(fig_EB, save_fig_name);

        fig_EB=figure(1);
        title(['Eyebrow Landmarks of ' curID 'for the animation:' curAU]);
        for n=1:length(landmark_col.eyebrows) %10 iteration
            EB(n).temp=landmark_eyebrows(:,2*n-1:2*n);
            subplot(length(landmark_col.eyebrows),1,n)
            for k=2:length(EB(n).temp)
                EB(n).x_dif_from_last_frame(k-1)=EB(n).temp(k,1)-EB(n).temp(end,1);
                EB(n).y_dif_from_last_frame(k-1)=EB(n).temp(k,2)-EB(n).temp(end,2);
                EB(n).temp_dif_from_last_frame(k-1)=sqrt(EB(n).x_dif_from_last_frame(k-1).^2 + EB(n).y_dif_from_last_frame(k-1).^2);
            end
            bar(EB(n).temp_dif_from_last_frame)
            legend(['Eyebrow Landmark:' num2str(n)],'Location','westoutside',...
                        'Orientation','horizontal');
        end
            save_fig_name=[curID '_' curAU '_LandmarkEyebrows_neutral_pose.fig'];
            saveas(fig_EB, save_fig_name); 
            fname_EB=[curID '_' curAU '_Landmark_EB_results.mat'];
            save(fname_EB, 'EB')
            
        % Plotting eye landmarks
%         fig_E=figure(2);
%         for n=1:length(landmark_col.eyes)
%             E(n).temp=landmark_eyes(:,2*n-1:2*n);
%             subplot(length(landmark_col.eyes),1,n)
%             for k=2:length(E(n).temp)
%                 E(n).x_dif(k-1)=E(n).temp(k,1)-E(n).temp(k-1,1);
%                 E(n).y_dif(k-1)=E(n).temp(k,2)-E(n).temp(k-1,2);
%                 E(n).temp_dif(k-1)=sqrt(E(n).x_dif(k-1).^2 + E(n).y_dif(k-1).^2);
%             end
%             bar(E(n).temp_dif)
%             ylim([0 1])
%             legend(['Eye Landmark:' num2str(n)],'Location','westoutside',...
%                         'Orientation','horizontal');
%         end
%             save_fig_name=[curID '_' curAU '_LandmarkEyes.fig'];
%             saveas(fig_E, save_fig_name);
        
        fig_E=figure(2);
        title(['Eye Landmarks of ' curID 'for the animation:' curAU]);
        for n=1:length(landmark_col.eyes)
            E(n).temp=landmark_eyes(:,2*n-1:2*n);
            subplot(length(landmark_col.eyes),1,n)
            for k=2:length(E(n).temp)
                E(n).x_dif_from_last_frame(k-1)=E(n).temp(k,1)-E(n).temp(end,1);
                E(n).y_dif_from_last_frame(k-1)=E(n).temp(k,2)-E(n).temp(end,2);
                E(n).temp_dif_from_last_frame(k-1)=sqrt(E(n).x_dif_from_last_frame(k-1).^2 + E(n).y_dif_from_last_frame(k-1).^2);
            end
            bar(E(n).temp_dif_from_last_frame)
            legend(['Eye Landmark:' num2str(n)],'Location','westoutside',...
                        'Orientation','horizontal');
        end
            save_fig_name=[curID '_' curAU '_LandmarkEyes_neutral_pose.fig'];
            saveas(fig_E, save_fig_name);
            fname_E=[curID '_' curAU '_Landmark_E_results.mat'];
            save(fname_E, 'E');

%         Plotting mouth landmarks
%         fig_M=figure(3);
%         for n=1:length(landmark_col.mouth)
%             M(n).temp=landmark_mouth(:,2*n-1:2*n);
%             subplot(length(landmark_col.mouth),1,n)
%             for k=2:length(M(n).temp)
%                 M(n).x_dif(k-1)=M(n).temp(k,1)-M(n).temp(k-1,1);
%                 M(n).y_dif(k-1)=M(n).temp(k,2)-M(n).temp(k-1,2);
%                 M(n).temp_dif(k-1)=sqrt(M(n).x_dif(k-1).^2 + M(n).y_dif(k-1).^2);
%             end
%             bar(M(n).temp_dif)
%             ylim([0 1])
%             legend(['Mouth Landmark:' num2str(n)],'Location','westoutside',...
%                         'Orientation','horizontal');
%         end
%             save_fig_name=[curID '_' curAU '_LandmarkMouth.fig'];
%             saveas(fig_M, save_fig_name);

        fig_M=figure(3);
        title(['Mouth Landmarks of ' curID 'for the animation:' curAU]);
        for n=1:length(landmark_col.mouth)
            M(n).temp=landmark_mouth(:,2*n-1:2*n);
            subplot(length(landmark_col.mouth),1,n)
            for k=2:length(M(n).temp)
                M(n).x_dif_from_last_frame(k-1)=M(n).temp(k,1)-M(n).temp(end,1);
                M(n).y_dif_from_last_frame(k-1)=M(n).temp(k,2)-M(n).temp(end,2);
                M(n).temp_dif_from_last_frame(k-1)=sqrt(M(n).x_dif_from_last_frame(k-1).^2 + M(n).y_dif_from_last_frame(k-1).^2);
            end
            bar(M(n).temp_dif_from_last_frame)
            legend(['Mouth Landmark:' num2str(n)],'Location','westoutside',...
                        'Orientation','horizontal');
        end
            save_fig_name=[curID '_' curAU '_LandmarkMouth_neutral_pose.fig'];
            saveas(fig_M, save_fig_name);
            fname_M=[curID '_' curAU '_Landmark_M_results.mat'];
            save(fname_M, 'M');
        
        % Plotting nose landmarks
%         fig_N=figure(4);
%         for n=1:length(landmark_col.nose)
%             N(n).temp=landmark_nose(:,2*n-1:2*n);
%             subplot(length(landmark_col.nose),1,n)
%             for k=2:length(N(n).temp)
%                 N(n).x_dif(k-1)=N(n).temp(k,1)-N(n).temp(k-1,1);
%                 N(n).y_dif(k-1)=N(n).temp(k,2)-N(n).temp(k-1,2);
%                 N(n).temp_dif(k-1)=sqrt(N(n).x_dif(k-1).^2 + N(n).y_dif(k-1).^2);
%             end
%             bar(N(n).temp_dif)
%             ylim([0 1])
%             legend(['Nose Landmark:' num2str(n)],'Location','westoutside',...
%                         'Orientation','horizontal');
%         end
%             save_fig_name=[curID '_' curAU '_LandmarkNose.fig'];
%             saveas(fig_N, save_fig_name);
            
        fig_N=figure(4);
        title(['Nose Landmarks of ' curID 'for the animation:' curAU]);
        for n=1:length(landmark_col.nose)
            N(n).temp=landmark_nose(:,2*n-1:2*n);
            subplot(length(landmark_col.nose),1,n)
            for k=2:length(N(n).temp)
                N(n).x_dif_from_last_frame(k-1)=N(n).temp(k,1)-N(n).temp(end,1);
                N(n).y_dif_from_last_frame(k-1)=N(n).temp(k,2)-N(n).temp(end,2);
                N(n).temp_dif_from_last_frame(k-1)=sqrt(N(n).x_dif_from_last_frame(k-1).^2 + N(n).y_dif_from_last_frame(k-1).^2);
            end
            bar(N(n).temp_dif_from_last_frame)
            legend(['Nose Landmark:' num2str(n)],'Location','westoutside',...
                        'Orientation','horizontal');
        end
            save_fig_name=[curID '_' curAU '_LandmarkNose_neutral_pose.fig'];
            saveas(fig_N, save_fig_name);
            fname_N=[curID '_' curAU '_Landmark_N_results.mat'];
            save(fname_N, 'N');
            
        % Drawing landmarks
%         fig_drawEB=figure();
%         for t=1:size(landmark_eyebrows,1) %frame num
%             clf
%             axis([0 1000 0 1000]);
%             for p=1:length(landmark_col.eyebrows) %10 landmarks
%                 drawpoint('Position',[1000-landmark_eyebrows(t,2*p-1) 1000-landmark_eyebrows(t,2*p)]);
%             end
%             movieVector(t)=getframe;
%         end
%         myWriter=VideoWriter([curID '_' curAU 'Landmark_EB']);
%         myWriter.FrameRate=20;
%         open(myWriter);
%         writeVideo(myWriter, movieVector);
%         close(myWriter)
%         
%         fig_drawE=figure(); %you must find a way to make an eye shape
%         for t=1:size(landmark_eyes,1)
%             clf
%             axis([0 1000 0 1000]);
%             for p=1:length(landmark_col.eyes) %12 landmarks
%                 drawpoint('Position',[1000-landmark_eyes(t,2*p-1) 1000-landmark_eyes(t,2*p)]);
%             end
%             movieVector(t)=getframe;
%         end
%         myWriter=VideoWriter([curID '_' curAU 'Landmark_E']);
%         myWriter.FrameRate=20;
%         open(myWriter);
%         writeVideo(myWriter, movieVector);
%         close(myWriter)
%         
%         fig_drawM=figure(); % you must find a way to make a mouth shape
%         for t=1:size(landmark_mouth,1)
%             clf
%             axis([0 1000 0 1000]);
%             for p=1:length(landmark_col.mouth) %20 landmarks
%                 drawpoint('Position',[1000-landmark_mouth(t,2*p-1) 1000-landmark_mouth(t,2*p)]);
%             end
%             movieVector(t)=getframe;
%         end
%         myWriter=VideoWriter([curID '_' curAU 'Landmark_M']);
%         myWriter.FrameRate=20;
%         open(myWriter);
%         writeVideo(myWriter, movieVector);
%         close(myWriter)
%         
%         fig_drawN=figure(); % you must find a way to make a nose shape
%         for t=1:size(landmark_nose,1)
%             clf
%             axis([0 1000 0 1000]);
%             for p=1:length(landmark_col.nose) %10 landmarks
%                 drawpoint('Position',[1000-landmark_nose(t,2*p-1) 1000-landmark_nose(t,2*p)]);
%             end
%             movieVector(t)=getframe;
%         end
%         myWriter=VideoWriter([curID '_' curAU 'Landmark_N']);
%         myWriter.FrameRate=20;
%         open(myWriter);
%         writeVideo(myWriter, movieVector);
%         close(myWriter)
%         
%         close all
         out_name=[curID '_' curAU '_allVariables_new_Landmark'];
         save(out_name)
         EB=[];E=[];M=[];N=[];   
    end
    close all
end

%% Descriptives
for i=1:length(id)
    curID=id{i};
    for AU_count=1:length(expressions)%length(AU_names)
        %curAU=AU_names{AU_count};
        curAU=expressions{AU_count};
        %cd([path '\' curID '_' curAU '_OFvsAFAR_output'])
        cd([path '\landmark_results'])
        load([curID '_' curAU '_allVariables_new_Landmark.mat']) %the output
        %name is 'output' but for the coord_dif, it is 'output_coord_dif'
%         output(i).avatar=curID;
%         output(i).AU(AU_count).AUname=curAU;
        output_coord_dif(i).avatar=curID;
        output_coord_dif(i).AU(AU_count).AUname=curAU;
        output_coord_dif(i).AU(AU_count).coord_dif_EB=vertcat(EB.temp_dif_from_last_frame);
        EB_mat=output_coord_dif(i).AU(AU_count).coord_dif_EB;
        output_coord_dif(i).AU(AU_count).coord_dif_E=vertcat(E.temp_dif_from_last_frame);
        E_mat=output_coord_dif(i).AU(AU_count).coord_dif_E;
        output_coord_dif(i).AU(AU_count).coord_dif_M=vertcat(M.temp_dif_from_last_frame);
        M_mat=output_coord_dif(i).AU(AU_count).coord_dif_M;
        output_coord_dif(i).AU(AU_count).coord_dif_N=vertcat(N.temp_dif_from_last_frame);
        N_mat=output_coord_dif(i).AU(AU_count).coord_dif_N;

        output_coord_dif(i).AU(AU_count).EBmean=mean(EB_mat');
        output_coord_dif(i).AU(AU_count).EBmax=max(EB_mat');
        output_coord_dif(i).AU(AU_count).EBmin=min(EB_mat');
        output_coord_dif(i).AU(AU_count).EBmedian=median(EB_mat');
        
        output_coord_dif(i).AU(AU_count).Emean=mean(E_mat');
        output_coord_dif(i).AU(AU_count).Emax=max(E_mat');
        output_coord_dif(i).AU(AU_count).Emin=min(E_mat');
        output_coord_dif(i).AU(AU_count).Emedian=median(E_mat');
         
        output_coord_dif(i).AU(AU_count).Mmean=mean(M_mat');
        output_coord_dif(i).AU(AU_count).Mmax=max(M_mat');
        output_coord_dif(i).AU(AU_count).Mmin=min(M_mat');
        output_coord_dif(i).AU(AU_count).Mmedian=median(M_mat');
        
        output_coord_dif(i).AU(AU_count).Nmean=mean(N_mat');
        output_coord_dif(i).AU(AU_count).Nmax=max(N_mat');
        output_coord_dif(i).AU(AU_count).Nmin=min(N_mat');
        output_coord_dif(i).AU(AU_count).Nmedian=median(N_mat');

%         output(i).AU(AU_count).EB_temp_dif=vertcat(EB.temp_dif); % concatanates temp_dif values of each landmark point into a matrix as ...
%         % (landmark number, dif_count||frame-1) e.g. 10x59
%         EB_mat=output(i).AU(AU_count).EB_temp_dif;
%         output(i).AU(AU_count).E_temp_dif=vertcat(E.temp_dif);  % 12x59
%         E_mat=output(i).AU(AU_count).E_temp_dif;
%         output(i).AU(AU_count).M_temp_dif=vertcat(M.temp_dif);  % 20x59
%         M_mat=output(i).AU(AU_count).M_temp_dif;
%         output(i).AU(AU_count).N_temp_dif=vertcat(N.temp_dif);  % 9x59
%         N_mat=output(i).AU(AU_count).N_temp_dif;
%         
%         output(i).AU(AU_count).EBmean=mean(EB_mat');
%         output(i).AU(AU_count).EBmax=max(EB_mat');
%         output(i).AU(AU_count).EBmin=min(EB_mat');
%         output(i).AU(AU_count).EBmedian=median(EB_mat');
%         
%         output(i).AU(AU_count).Emean=mean(E_mat');
%         output(i).AU(AU_count).Emax=max(E_mat');
%         output(i).AU(AU_count).Emin=min(E_mat');
%         output(i).AU(AU_count).Emedian=median(E_mat');
%          
%         output(i).AU(AU_count).Mmean=mean(M_mat');
%         output(i).AU(AU_count).Mmax=max(M_mat');
%         output(i).AU(AU_count).Mmin=min(M_mat');
%         output(i).AU(AU_count).Mmedian=median(M_mat');
%         
%         output(i).AU(AU_count).Nmean=mean(N_mat');
%         output(i).AU(AU_count).Nmax=max(N_mat');
%         output(i).AU(AU_count).Nmin=min(N_mat');
%         output(i).AU(AU_count).Nmedian=median(N_mat');
       close all
    end
    
end
%save output output
save output_coord_dif output_coord_dif
%% Correlation
cd([path '\landmark_results'])
load('output_coord_dif.mat')
for AU_count=1:length(expressions)%length(AU_names)
%    curAU=AU_names{AU_count};
    curAU=expressions{AU_count};
%     corl(AU_count).AUname=curAU;
%     
%     corl(AU_count).corl_EB=corr(output(1).AU(AU_count).EB_temp_dif(:), output(2).AU(AU_count).EB_temp_dif(:), 'Type', 'Spearman');
%     corl(AU_count).corl_E=corr(output(1).AU(AU_count).E_temp_dif(:), output(2).AU(AU_count).E_temp_dif(:), 'Type', 'Spearman');
%     corl(AU_count).corl_M=corr(output(1).AU(AU_count).M_temp_dif(:), output(2).AU(AU_count).M_temp_dif(:), 'Type', 'Spearman');
%     corl(AU_count).corl_N=corr(output(1).AU(AU_count).N_temp_dif(:), output(2).AU(AU_count).N_temp_dif(:), 'Type', 'Spearman');
%     
    corl_coord_dif(AU_count).AUname=curAU;
    
    corl_coord_dif(AU_count).corl_EB=corr(output_coord_dif(1).AU(AU_count).coord_dif_EB(:), output_coord_dif(2).AU(AU_count).coord_dif_EB(:)); %, 'Type', 'Spearman');
    corl_coord_dif(AU_count).corl_E=corr(output_coord_dif(1).AU(AU_count).coord_dif_E(:), output_coord_dif(2).AU(AU_count).coord_dif_E(:)); %, 'Type', 'Spearman');
    corl_coord_dif(AU_count).corl_M=corr(output_coord_dif(1).AU(AU_count).coord_dif_M(:), output_coord_dif(2).AU(AU_count).coord_dif_M(:)); %, 'Type', 'Spearman');
    corl_coord_dif(AU_count).corl_N=xcorr(output_coord_dif(1).AU(AU_count).coord_dif_N(:), output_coord_dif(2).AU(AU_count).coord_dif_N(:)); %, 'Type', 'Spearman');
        
    
end
%save corl corl
save corl_coord_dif corl_coord_dif