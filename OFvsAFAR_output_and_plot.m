% How to analyze?
% 1- determine the overlapping AUs between two  softwares
%    - load OF and AFAR data
% 2- plot the AU intensity range for overlapping AUs in two columns (OF &
%    AFAR) ==> 3 plots and colormaps: OF, AFAR, OF and AFAR Together
%    - example: plotAUNoVideo.m
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% MH_path= ['C:\Users\hilal\Desktop\JLU-Dobs\MetaHuman Recordings\Trimmed Videos\'];
% id= {'Cooper', 'Lena', 'Ettore'};
% expressions={'Amaze-A', 'Amaze-B', 'Anger-A', 'Anger-B', 'Face-ROM', ...
%     'Fear-A', 'Fear-B', 'Happy-A', 'Happy-B', 'Idle', 'Sad-A', 'Sad-B'};
% expressions={'Amaze-B', 'Anger-B', 'Face-ROM', 'Fear-B', 'Happy-B', 'Sad-B'};

% analysis_path=['C:\Users\hilal\Desktop\JLU-Dobs\MetaHuman Recordings\Analysis\'];
% cd(analysis_path)


path=['C:\Users\hilal\Desktop\JLU-Dobs\MetaHuman Recordings\UnrealEngine_Animations\'];
id={'Ada','Garry','Cooper','Pia'};
AU_names={'AU01','AU02','AU04','AU06','AU07','AU10','AU12','AU14','AU15',...
    'AU17','AU23','browsAll','browsAU10','browsAU12','browsAU14','browsAU15','browsAU17','browsAU23'};
cd(path)

output=[];
for i=4%3:length(id)
    curID=id{i};
    for j=[10,17]%1:length(AU_names) %length(expressions)
        %curEXP=expressions{j};
        curAU=AU_names{j};
        OF_fname=[path curID '\OpenFace_output\' curID '_' curAU '_OF-results.mat'];
        AFAR_fname=[path curID '\AFAR_output\' curID '_' curAU '_AFAR-results.mat'];
        output.OF_fname=OF_fname;
        output.AFAR_fname=AFAR_fname;
        load(OF_fname);
        load(AFAR_fname);
        cd(path)
        %matching AU names of OF and AFAR -e.g. AU01
        for n = 1: length(AFARresults.AUnames)
            if length(AFARresults.AUnames{n}) <4 %<9 %<4
                AUname=[AFARresults.AUnames{n}(1:2), '0', AFARresults.AUnames{n}(3)];
                AFARresults.AUnames{n}=AUname;
            else
                AFARresults.AUnames{n}=AFARresults.AUnames{n}(1:4); 
            end
        end
        for k = 1: length(OFresults.AUnames)
            AUname=OFresults.AUnames{k}(1:4);
            OFresults.AUnames{k}=AUname;
        end
        OF_data=OFresults.AUs;
        AFAR_data=AFARresults.AUs;
        output.OF_data=OF_data;
        output.AFAR_data=AFAR_data;
        
        AFAR_AUnames=AFARresults.AUnames;
        AFAR_AUnames_arr=[];
        for n=1:length(AFAR_AUnames)
            AFAR_AUnames_arr=[AFAR_AUnames_arr; AFAR_AUnames{n}];
        end
        output.AFAR_AUnames=AFAR_AUnames_arr;
        
        OF_AUnames=OFresults.AUnames;
        OF_AUnames_arr=[];
        for n=1:length(OF_AUnames)
            OF_AUnames_arr=[OF_AUnames_arr; OF_AUnames{n}];
        end
        output.OF_AUnames=OF_AUnames_arr;
        
        overlapping_ind_OF=contains(OF_AUnames,AFAR_AUnames);
        
        overlapping_OFdata=OF_data(:,overlapping_ind_OF); 
        output.overlapping_OFdata=overlapping_OFdata;
        output.min_overlapping_OFdata=min(overlapping_OFdata);
        output.max_overlapping_OFdata=max(overlapping_OFdata);
        output.mean_overlapping_OFdata=mean(overlapping_OFdata);
        output.var_overlapping_OFdata=var(overlapping_OFdata);
         
        overlappingAU=OF_AUnames(overlapping_ind_OF);
        output.overlappingAUnames=overlappingAU;
        
        overlapping_ind_AFAR=contains(AFAR_AUnames,OF_AUnames);
        overlapping_AFARdata=AFAR_data(:,overlapping_ind_AFAR);
        output.overlapping_AFARdata=overlapping_AFARdata; 
        output.min_overlapping_AFARdata=min(overlapping_AFARdata);
        output.max_overlapping_AFARdata=max(overlapping_AFARdata);
        output.mean_overlapping_AFARdata=mean(overlapping_AFARdata);
        output.var_overlapping_AFARdata=var(overlapping_AFARdata);
        
        save_output_name=[curID '_' curAU '_OFvsAFAR_output.mat'];
        save_folder=[curID '_' curAU '_OFvsAFAR_output'];
        cd(path)
        mkdir(save_folder)
        cd(save_folder)
        
        output.corr_OF_AFAR_full=corr(overlapping_OFdata(:), overlapping_AFARdata(:), 'Type', 'Spearman');
        for n=1:length(overlappingAU)
            output.corr_OF_AFAR_AUwise(n)=corr(overlapping_OFdata(:,n), overlapping_AFARdata(:,n), 'Type', 'Spearman');
            mat=[overlapping_OFdata(:,n);overlapping_AFARdata(:,n)];
            X=pdist(mat);
            RDM=squareform(X);
            output.RDM_OF_AFAR_AUwise{n}=RDM;
            fig_RDM=figure();
            imagesc(RDM)
            %title(['RDM of OF and AFAR for AU' sprintf('%02d',n)])
            title(['RDM of OF and AFAR for ' overlappingAU{n}]);
            colorbar();
            caxis([0 1]);
            save_fig_name=[curID '_' curAU '_' overlappingAU{n} '_RDM_colormap.fig'];
            saveas(fig_RDM, save_fig_name);
            close all;
        end
        
        % plotting (frame, AU)
        
        % linspace(x1, x2, n):
        % Create a vector of n evenly spaced points in the interval [x1, x2]
        x = linspace(1,size(overlapping_OFdata,1),size(overlapping_OFdata,1));
                
        fig_OF= figure(1); 
        for n = 1 : length(overlappingAU)
            subplot(length(overlappingAU),1,n)
            title('OF results')
            plot(x,overlapping_OFdata(:,n)); 
            axis([1 size(overlapping_OFdata,1) 0 1])
            legend([overlappingAU{n} '   '],'Location','westoutside',...
                'Orientation','horizontal');
        end
        output.fig_OF=fig_OF;
        save_fig_name=[curID '_' curAU '_OF_plot.fig'];
        saveas(fig_OF, save_fig_name);
        
        fig_AFAR=figure(2);
        for n = 1 : length(overlappingAU)
            subplot(length(overlappingAU),1,n)
            title('AFAR results')
            plot(x,overlapping_AFARdata(:,n));
            axis([1 size(overlapping_OFdata,1) 0 5])
            legend([overlappingAU{n} '   '],'Location','westoutside',...
                'Orientation','horizontal');
        end
        output.fig_AFAR=fig_AFAR;
        save_fig_name=[curID '_' curAU '_AFAR_plot.fig'];
        saveas(fig_AFAR, save_fig_name);

        fig_ALL=figure(3);
        for n = 1 : length(overlappingAU)
            subplot(length(overlappingAU),1,n)
            plot(x,overlapping_OFdata(:,n));
            axis([1 size(overlapping_OFdata,1) 0 5])
            
            hold on
            
            subplot(length(overlappingAU),1,n)
            plot(x,overlapping_AFARdata(:,n));
            axis([1 size(overlapping_OFdata,1) 0 1])
            legend('OF', 'AFAR','Location','eastoutside',...
                 'Orientation','horizontal');
        end
        output.fig_ALL=fig_ALL;
        save_fig_name=[curID '_' curAU '_ALL_plot.fig'];
        saveas(fig_ALL, save_fig_name);
        
        % Drawing the colormap/heatmap of the line plots
        fig_AFARcolormap=figure(4);
        imagesc(overlapping_AFARdata')
        colormap(gca,'parula');
        colorbar();
        caxis([0 1]);
        yticklabels(overlappingAU);
        output.fig_AFARcolormap=fig_AFARcolormap;
        save_fig_name=[curID '_' curAU '_AFAR_colormap.fig'];
        saveas(fig_AFARcolormap, save_fig_name);
        
        fig_OF_colormap=figure(5);
        imagesc(overlapping_OFdata')
        colormap(gca,'parula');
        colorbar();
        caxis([0 5]);
        yticklabels(overlappingAU);
        output.fig_OFcolormap=fig_OF_colormap;
        save_fig_name=[curID '_' curAU '_OF_colormap.fig'];
        saveas(fig_OF_colormap, save_fig_name);

        save(save_output_name, 'output')
        close all
    end
end