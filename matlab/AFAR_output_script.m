clear all; clc

AFARresults=[];
id={'Ada','Garry','Cooper','Pia'};
%% Paths
% data_root points at the dataset in this repository.  The rendered
% animation videos and the raw per-detector output directories are not
% committed, so set data_root to a local copy of them when re-running a
% step that needs them.  Separators below are Windows-style, as in the
% run the published results come from.  See README.md.
data_root=['..' filesep 'ds-au_detection_mh' filesep 'sourcedata' filesep];
path=data_root;
AU_names={'AU01','AU02','AU04','AU06','AU07','AU10','AU12','AU14','AU15',...
    'AU17','AU23','browsAll','browsAU10','browsAU12','browsAU14','browsAU15','browsAU17','browsAU23'};
%read table
for i=4%3:length(id)
    AFARresults.id=id{i};
    for n=[10,17]%1:length(AU_names) %length(expressions)
        %AFARresults.exp=expressions{n};
        AFARresults.AU=AU_names{n};
        % Reading csv file of OpenFace output
        AFAR_out_path= [path id{i} '\AFAR_output\'];
        cd(AFAR_out_path)
        AFARresults.cd=AFAR_out_path;
        
        fname= [id{i} '_' AU_names{n} '_au_out.mat'];
        AFAR_out= load(fname);
        AFARresults.table=AFAR_out.result;

        frames=size(AFAR_out.result);
        AFARresults.frames=frames;

        AUs=AFAR_out.result{:, :}; %13:end}; %this is directly for the analysis, skip scores(in the new version of afar it also outputs scores), only take probabilities
        AFARresults.AUs=AUs;
        AFARresults.AUnames=AFAR_out.result.Properties.VariableNames;%(13:end);

        %Save as results_id_exp
        cd(AFAR_out_path)
        save_path=[AFARresults.id '_' AFARresults.AU '_AFAR-results.mat'];
        save(save_path, 'AFARresults');
    end
end
