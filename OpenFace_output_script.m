% Details
OFresults=[];
%MH_path= ['C:\Users\hilal\Desktop\JLU-Dobs\MetaHuman Recordings\Trimmed Videos\'];
%id= {'Cooper', 'Lena', 'Ettore'};
% expressions={'Amaze-A', 'Amaze-B', 'Anger-A', 'Anger-B', 'Face-ROM', ...
%     'Fear-A', 'Fear-B', 'Happy-A', 'Happy-B', 'Idle', 'Sad-A', 'Sad-B'};
%expressions={'Amaze-B', 'Anger-B', 'Fear-B', 'Happy-B', 'Sad-B'};
id={'Ada','Garry','Cooper','Pia'};
path=['C:\Users\hilal\Desktop\JLU-Dobs\MetaHuman Recordings\UnrealEngine_Animations\'];
AU_names={'AU01','AU02','AU04','AU06','AU07','AU10','AU12','AU14','AU15',...
    'AU17','AU23','browsAll','browsAU10','browsAU12','browsAU14','browsAU15','browsAU17','browsAU23'};

for i=4%3:length(id)
     OFresults.id=id{i};
    for n=  [10,17]%1:length(AU_names) %length(expressions)
        %OFresults.exp=expressions{n};
        OFresults.AU=AU_names{n};
        
        % Reading csv file of OpenFace output
        OF_out_path= [path id{i} '\OpenFace_output'];
        cd(OF_out_path)
        OFresults.cd=OF_out_path;
        
        %csv_fname= ['MetaHuman Creator - ' id{i} '_' expressions{n} '.csv'];
        %csv_fname= [id{i} '_' expressions{n} ' - Trim.csv'];
        csv_fname=[id{i} '_' AU_names{n} '.csv'];
        OF_out= readtable(csv_fname);
        OFresults.table=OF_out;

        frames=OF_out.frame(:);
        OFresults.frames=frames;

        AUs=OF_out{1:end, 680:695}; %this is directly for the analysis
        OFresults.AUs=AUs;
        for k=1:696-680
            AUnames{k}=OF_out.Properties.VariableNames{:,680+k-1};
        end
        OFresults.AUnames=AUnames;

        %Save as results_id_exp
%         analysis_path=['C:\Users\hilal\Desktop\JLU-Dobs\MetaHuman Recordings\Analysis'];
%         cd(analysis_path)
        cd(OF_out_path)
        %save_path=[OFresults.id '_' OFresults.exp '_OF-results.mat'];
        save_path=[OFresults.id '_' OFresults.AU '_OF-results.mat'];
        save(save_path, 'OFresults');
    end
end
