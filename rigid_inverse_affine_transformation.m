%% Inital path and param
main_path=['C:\Users\hilal\Desktop\JLU-Dobs\MetaHuman Recordings\_UnrealEngine_Animations'];
MHs={'Ada','Garry','Cooper','Pia'};
gender_id={'w','m','m','w'};
m_ind=find(strcmp(gender_id,'m'));
w_ind=find(strcmp(gender_id,'w'));
animations={'AU01','AU02','AU04','AU06','AU07','AU10' ...
            'AU12','AU14','AU15','AU17','AU23','browsAll'...
            'browsAU10','browsAU12','browsAU14','browsAU15','browsAU17','browsAU23'};
AUs_only_anim=animations(1:end-7);
%% Load CSV and apply Inverse Affine Transformation
for id=1:length(MHs)
    curID=MHs{id};
    OFresults(id).avatar=curID;
    % Reading csv file of OpenFace output
    OF_out_path= [main_path '\' curID '\OpenFace_output\'];
    cd(OF_out_path)
    OFresults(id).OF_csv_path=OF_out_path;

    for exp=1:length(animations)
        OFresults(id).landmarks(exp).curAvatar=curID;
        curAnim=animations{exp};
        OFresults(id).landmarks(exp).curAnim=curAnim;
        cd(OF_out_path)
        files=dir('*.csv');
        csv_fname=files(exp).name;
        OF_out= readtable(csv_fname);
        OFresults(id).landmarks(exp).table=OF_out;

        % LANDMARKS in 3D =[x ; y ; z] --> L(:,i) : ith landmark's coordinates
        EB_x_cols=[453:462]; EB_y_cols=[521:530]; EB_z_cols=[589:598]; % 17:26; 10 Ls; table column numbers for eyebrow landmarks
        E_x_cols=[472:483]; E_y_cols=[540:551]; E_z_cols=[608:619]; % 36:47; 12 Ls; table column numbers for eye landmarks
        N_x_cols=[463:471]; N_y_cols=[531:539]; N_z_cols=[599:607]; % 27:35; 9 Ls; table column numbers for nose landmarks
        M_x_cols=[484:503]; M_y_cols=[552:571]; M_z_cols=[620:639]; % 48:67; 20 Ls; table column numbers for mouth landmarks

         % LANDMARKS in 2D =[x ; y] --> L(:,i) : ith landmark's coordinates
        EB_2d_x=[317:326]; EB_2d_y=[385:394]; % 17:26; 10 Ls; table column numbers for eyebrow landmarks
        E_2d_x=[336:347]; E_2d_y=[404:415]; % 36:47; 12 Ls; table column numbers for eye landmarks
        N_2d_x=[327:335]; N_2d_y=[395:403]; % 27:35; 9 Ls; table column numbers for nose landmarks
        M_2d_x=[348:367]; M_2d_y=[416:435]; % 48:67; 20 Ls; table column numbers for mouth landmarks  

        trans_x_cols=294; trans_y_cols=295; trans_z_cols=296;
        rot_x_cols= 297; rot_y_cols= 298; rot_z_cols=299;

        x = linspace(1,size(OF_out,1),size(OF_out,1)); % creating linspace for plotting

        landmark_eyebrows_x=OF_out(:,EB_x_cols); landmark_eyebrows_x=table2array(landmark_eyebrows_x); % 150 x10: 150 frames by 10 (x)s: landmark_eyebrows(frames, 3n-2:3n)
        landmark_eyebrows_y=OF_out(:,EB_y_cols); landmark_eyebrows_y=table2array(landmark_eyebrows_y); % 150 x10: 150 frames by 10 (y)s: landmark_eyebrows(frames, 3n-2:3n)
        landmark_eyebrows_z=OF_out(:,EB_z_cols); landmark_eyebrows_z=table2array(landmark_eyebrows_z); % 150 x10: 150 frames by 10 (z)s: landmark_eyebrows(frames, 3n-2:3n)
        OFresults(id).landmarks(exp).EB_3d=[landmark_eyebrows_x; landmark_eyebrows_y; landmark_eyebrows_z];

        landmark_eyes_x=OF_out(:,E_x_cols); landmark_eyes_x=table2array(landmark_eyes_x);
        landmark_eyes_y=OF_out(:,E_y_cols); landmark_eyes_y=table2array(landmark_eyes_y);
        landmark_eyes_z=OF_out(:,E_z_cols); landmark_eyes_z=table2array(landmark_eyes_z);
        OFresults(id).landmarks(exp).E_3d=[landmark_eyes_x; landmark_eyes_y; landmark_eyes_z];

        landmark_nose_x=OF_out(:,N_x_cols); landmark_nose_x=table2array(landmark_nose_x);
        landmark_nose_y=OF_out(:,N_y_cols); landmark_nose_y=table2array(landmark_nose_y);
        landmark_nose_z=OF_out(:,N_z_cols); landmark_nose_z=table2array(landmark_nose_z);
        OFresults(id).landmarks(exp).N_3d=[landmark_nose_x; landmark_nose_y; landmark_nose_z];

        landmark_mouth_x=OF_out(:,M_x_cols); landmark_mouth_x=table2array(landmark_mouth_x);
        landmark_mouth_y=OF_out(:,M_y_cols); landmark_mouth_y=table2array(landmark_mouth_y);
        landmark_mouth_z=OF_out(:,M_z_cols); landmark_mouth_z=table2array(landmark_mouth_z);
        OFresults(id).landmarks(exp).M_3d=[landmark_mouth_x; landmark_mouth_y; landmark_mouth_z];

        % ---------------------------
        landmark_eyebrows_2d_x=OF_out(:,EB_2d_x); landmark_eyebrows_2d_x=table2array(landmark_eyebrows_2d_x); % 150 x10: 150 frames by 10 (x)s: landmark_eyebrows(frames, 3n-2:3n)
        landmark_eyebrows_2d_y=OF_out(:,EB_2d_y); landmark_eyebrows_2d_y=table2array(landmark_eyebrows_2d_y); % 150 x10: 150 frames by 10 (y)s: landmark_eyebrows(frames, 3n-2:3n)
        OFresults(id).landmarks(exp).EB_2d=[landmark_eyebrows_2d_x; landmark_eyebrows_2d_y];

        landmark_eyes_2d_x=OF_out(:,E_2d_x); landmark_eyes_2d_x=table2array(landmark_eyes_2d_x);
        landmark_eyes_2d_y=OF_out(:,E_2d_y); landmark_eyes_2d_y=table2array(landmark_eyes_2d_y);
        OFresults(id).landmarks(exp).E_2d=[landmark_eyes_2d_x; landmark_eyes_2d_y];

        landmark_nose_2d_x=OF_out(:,N_2d_x); landmark_nose_2d_x=table2array(landmark_nose_2d_x);
        landmark_nose_2d_y=OF_out(:,N_2d_y); landmark_nose_2d_y=table2array(landmark_nose_2d_y);
        OFresults(id).landmarks(exp).N_2d=[landmark_nose_2d_x; landmark_nose_2d_y];

        landmark_mouth_2d_x=OF_out(:,M_2d_x); landmark_mouth_2d_x=table2array(landmark_mouth_2d_x);
        landmark_mouth_2d_y=OF_out(:,M_2d_y); landmark_mouth_2d_y=table2array(landmark_mouth_2d_y);
        OFresults(id).landmarks(exp).M_2d=[landmark_mouth_2d_x; landmark_mouth_2d_y];
        % ----------------------------
        trans_X=OF_out(:,trans_x_cols); trans_X=table2array(trans_X);
        trans_Y=OF_out(:,trans_y_cols); trans_Y=table2array(trans_Y);
        trans_Z=OF_out(:,trans_z_cols); trans_Z=table2array(trans_Z);
        OFresults(id).landmarks(exp).translation=[trans_X;trans_Y;trans_Z];
        
        rot_X=OF_out(:,rot_x_cols); rot_X=table2array(rot_X);
        rot_Y=OF_out(:,rot_y_cols); rot_Y=table2array(rot_Y);
        rot_Z=OF_out(:,rot_z_cols); rot_Z=table2array(rot_Z);
        OFresults(id).landmarks(exp).rotation=[rot_X;rot_Y;rot_Z];

        landm_all_x=[landmark_eyebrows_x landmark_eyes_x landmark_nose_x landmark_mouth_x];
        landm_all_y=[landmark_eyebrows_y landmark_eyes_y landmark_nose_y landmark_mouth_y];
        landm_all_z=[landmark_eyebrows_z landmark_eyes_z landmark_nose_z landmark_mouth_z];
        OFresults(id).landmarks(exp).landm_all_3d=[landm_all_x; landm_all_y; landm_all_z];

        landm_all_2d_x=[landmark_eyebrows_2d_x landmark_eyes_2d_x landmark_nose_2d_x landmark_mouth_2d_x];
        landm_all_2d_y=[landmark_eyebrows_2d_y landmark_eyes_2d_y landmark_nose_2d_y landmark_mouth_2d_y];
        OFresults(id).landmarks(exp).landm_all_2d=[landm_all_2d_x; landm_all_2d_y];

        % Inverse Affine Transformation
        for fr=1:length(rot_X)
            % Define angles in radians
            theta = rot_X(fr);  % Rotation around X-axis
            phi = rot_Y(fr);      % Rotation around Y-axis
            psi = rot_Z(fr);     % Rotation around Z-axis
            OFresults(id).landmarks(exp).frames(fr).rot_angles=[theta;phi;psi];

            % Define rotation matrices for Rx, Ry, Rz
            Rx = [1, 0, 0;
                0, cos(theta), -sin(theta);
                0, sin(theta), cos(theta)];

            Ry = [cos(phi), 0, sin(phi);
                0, 1, 0;
                -sin(phi), 0, cos(phi)];

            Rz = [cos(psi), -sin(psi), 0;
                sin(psi), cos(psi), 0;
                0, 0, 1];
            OFresults(id).landmarks(exp).frames(fr).rot_matrices=[Rx;Ry;Rz];

            % Combine rotations: R = Rx * Ry * Rz
            R = Rx * (Ry * Rz);
            OFresults(id).landmarks(exp).frames(fr).rot_comb=R;

            % Inverse rotation matrix (transpose of R)
            R_inv = R';
            OFresults(id).landmarks(exp).frames(fr).rot_inv=R_inv;

            % Example marker and head translation coordinates
            % Replace 'x_marker', 'y_marker', 'z_marker', 'x_head', 'y_head', 'z_head'
            % with actual values
            marker{fr} = [landm_all_x(fr,:); landm_all_y(fr,:); landm_all_z(fr,:)];
            translation{fr} = [trans_X(fr); trans_Y(fr); trans_Z(fr)];
            OFresults(id).landmarks(exp).frames(fr).marker=marker{fr};
            OFresults(id).landmarks(exp).frames(fr).translation=translation{fr};

            % Translate marker position back to origin
            translated_marker{fr} = marker{fr} - translation{fr};
            OFresults(id).landmarks(exp).frames(fr).translated_marker=translated_marker{fr};
            % Apply inverse rotation to the translated position
            corrected_marker{fr} = R_inv * translated_marker{fr};
            OFresults(id).landmarks(exp).frames(fr).corrected_marker=corrected_marker{fr};
        end
    end
end
cd([main_path '\Analyses\Inverse_affine_transform'])
save OFresults OFresults
%% Calculate and draw landmark position change 
cd([main_path '\Analyses\Inverse_affine_transform'])
load('OFresults.mat')
cd('./plots')
for id=1:length(MHs)
    curID=MHs{id};
    for exp=1:length(animations)
        curAnim=animations{exp};
        input=OFresults(id).landmarks(exp).frames;
        for fr=1:length(input) %iterate over 150 frames
            for landm= 1:length(input(fr).corrected_marker) %iterate over 51 landmarks
                x_dif=input(fr).corrected_marker(1,landm)-input(1).corrected_marker(1,landm); %difference from the initial frame
                y_dif=input(fr).corrected_marker(2,landm)-input(1).corrected_marker(2,landm); 
                z_dif=input(fr).corrected_marker(3,landm)-input(1).corrected_marker(3,landm);
                pos_change(fr,landm)=sqrt(x_dif.^2+y_dif.^2+z_dif.^2);
            end
        end
        OFresults(id).landmarks(exp).corrected_coord_dif= pos_change;
        
        % EB
        fig_pos_change_EB=figure();
        title(['Position Change of EB Landmarks for: sub-' curID '-' curAnim]);
        for landm=1:10 %EB
            subplot(10,1,landm)
            bar(pos_change(:,landm))
            legend(['Landmark EB#' num2str(landm)],'Location','westoutside',...
            'Orientation','horizontal');
        end
        save_fig_name=[curID '_' curAnim '_EB_Landmark_pose_change.fig'];
        saveas(fig_pos_change_EB, save_fig_name);
        % Eyes
        fig_pos_change_E=figure();
        title(['Position Change of Eyes Landmarks for: sub-' curID '-' curAnim]);
        count=0;
        for landm=11:22 %E
            count=count+1;
            subplot(12,1,count)
            bar(pos_change(:,landm))
            legend(['Landmark E#' num2str(count)],'Location','westoutside',...
            'Orientation','horizontal');
        end
        save_fig_name=[curID '_' curAnim '_E_Landmark_pose_change.fig'];
        saveas(fig_pos_change_E, save_fig_name);
        % Nose
        fig_pos_change_N=figure();
        title(['Position Change of Nose Landmarks for: sub-' curID '-' curAnim]);
        count=0;
        for landm=23:31 %N
            count=count+1;
            subplot(9,1,count)
            bar(pos_change(:,landm))
            legend(['Landmark N#' num2str(count)],'Location','westoutside',...
            'Orientation','horizontal');
        end
        save_fig_name=[curID '_' curAnim '_N_Landmark_pose_change.fig'];
        saveas(fig_pos_change_N, save_fig_name);
        % Mouth
        fig_pos_change_M=figure();
        title(['Position Change of Mouth Landmarks for: sub-' curID '-' curAnim]);
        count=0;
        for landm=32:51 %M
            count=count+1;
            subplot(20,1,count)
            bar(pos_change(:,landm))
            legend(['Landmark M#' num2str(count)],'Location','westoutside',...
            'Orientation','horizontal');
        end
        save_fig_name=[curID '_' curAnim '_M_Landmark_pose_change.fig'];
        saveas(fig_pos_change_M, save_fig_name);
        pos_change=[];
    end
    close all;
end
cd([main_path '\Analyses\Inverse_affine_transform'])
save OFresults OFresults

%% Create motion_params.mat

%% Motion parameters: rotation mat vectorized, translation, landm_eucld
rot_vect_arr=[]; trans_vect_arr=[]; max_rot_arr=[]; max_trans_arr=[];
max_x_pos_arr=[]; max_x_neg_arr=[]; max_x_dir_arr=[]; 
max_y_pos_arr=[]; max_y_neg_arr=[]; max_y_dir_arr=[]; 
max_z_pos_arr=[]; max_z_neg_arr=[]; max_z_dir_arr=[]; 
max_coord_eucl_dif_arr=[];
for id=1:length(MHs)
    curID=MHs{id};
    motion_params(id).avatar=curID;
    % Reading csv file of OpenFace output
    OF_out_path= [main_path '\' curID '\OpenFace_output\'];
    motion_params(id).OF_csv_path=OF_out_path;
    for exp=1:length(animations)
        curExp=animations{exp};
        motion_params(id).videos(exp).curExp=curExp;
        motion_params(id).videos(exp).avatar=curID;

        all_frames=OFresults(id).landmarks(exp).frames;
        blank=zeros(length(all_frames),51);
        x_pos=blank; y_pos=blank; z_pos=blank; x_neg=blank; y_neg=blank; z_neg=blank;
        x_dir=blank; y_dir=blank; z_dir=blank; coord_eucl_dif=blank;
        for fr=1:length(all_frames)
            rot_vect=all_frames(fr).rot_comb(:);  %9x1 vector
            trans=all_frames(fr).translation-all_frames(1).translation;  %3x1 vector
            rot_vect_arr=[rot_vect_arr rot_vect];
            trans_vect_arr=[trans_vect_arr trans];
            for landm= 1:length(all_frames(fr).corrected_marker) %iterate over 51 landmarks
                x_dif=all_frames(fr).corrected_marker(1,landm)-all_frames(1).corrected_marker(1,landm); %difference from the initial frame
                x_dir(fr,landm)=x_dif;
                if x_dif >=0
                    x_pos(fr,landm)=abs(x_dif);
                else
                    x_neg(fr,landm)=abs(x_dif);
                end
                y_dif=all_frames(fr).corrected_marker(2,landm)-all_frames(1).corrected_marker(2,landm); 
                y_dir(fr,landm)=y_dif;
                if y_dif >=0
                    y_pos(fr,landm)=abs(y_dif);
                else 
                    y_neg(fr,landm)=abs(y_dif);
                end
                z_dif=all_frames(fr).corrected_marker(3,landm)-all_frames(1).corrected_marker(3,landm);
                z_dir(fr,landm)=z_dif;
                if z_dif >=0
                    z_pos(fr,landm)=abs(z_dif);
                else
                    z_neg(fr,landm)=abs(z_dif);
                end
                coord_dif(fr,landm,:)=[x_dif; y_dif; z_dif];
                coord_eucl_dif(fr,landm)=sqrt(x_dif.^2 + y_dif.^2 + z_dif.^2);
                x_dif=[]; y_dif=[]; z_dif=[];
            end
        end
        motion_params(id).videos(exp).rot_vect=rot_vect_arr;
        motion_params(id).videos(exp).trans_vect=trans_vect_arr;
        maxs_rot=max(rot_vect_arr');
        motion_params(id).videos(exp).max_rot=maxs_rot;
        maxs_trans=max(trans_vect_arr');
        motion_params(id).videos(exp).max_trans=maxs_trans;
        rot_vect_arr=[]; trans_vect_arr=[]; maxs_rot=[]; maxs_trans=[];
        max_rot_arr=[max_rot_arr; motion_params(id).videos(exp).max_rot];
        max_trans_arr=[max_trans_arr; motion_params(id).videos(exp).max_trans];
        
        motion_params(id).videos(exp).x_pos= x_pos;
        motion_params(id).videos(exp).x_neg= x_neg;
        motion_params(id).videos(exp).x_dir= x_dir;
        motion_params(id).videos(exp).y_pos= y_pos;
        motion_params(id).videos(exp).y_neg= y_neg;
        motion_params(id).videos(exp).y_dir= y_dir;
        motion_params(id).videos(exp).z_pos= z_pos;
        motion_params(id).videos(exp).z_neg= z_neg;
        motion_params(id).videos(exp).z_dir= z_dir;
        motion_params(id).videos(exp).coord_eucl_dif=coord_eucl_dif; 
        motion_params(id).videos(exp).coord_dif=coord_dif; coord_dif=[];

        maxs_x_pos=max(x_pos);
        motion_params(id).videos(exp).x_pos_max= maxs_x_pos;
        maxs_x_pos=[]; x_pos=[];
        max_x_pos_arr=[max_x_pos_arr; motion_params(id).videos(exp).x_pos_max]; 

        maxs_x_neg=max(x_neg); 
        motion_params(id).videos(exp).x_neg_max= maxs_x_neg;
        maxs_x_neg=[]; x_neg=[];
        max_x_neg_arr=[max_x_neg_arr; motion_params(id).videos(exp).x_neg_max];

        maxs_x_dir=max(x_dir); 
        motion_params(id).videos(exp).x_dir_max= maxs_x_dir;
        maxs_x_dir=[]; x_dir=[];
        max_x_dir_arr=[max_x_dir_arr; motion_params(id).videos(exp).x_dir_max];

        maxs_y_pos=max(y_pos);
        motion_params(id).videos(exp).y_pos_max= maxs_y_pos;
        maxs_y_pos=[]; y_pos=[];
        max_y_pos_arr=[max_y_pos_arr; motion_params(id).videos(exp).y_pos_max];

        maxs_y_neg=max(y_neg); 
        motion_params(id).videos(exp).y_neg_max= maxs_y_neg;
        maxs_y_neg=[]; y_neg=[];
        max_y_neg_arr=[max_y_neg_arr; motion_params(id).videos(exp).y_neg_max];

        maxs_y_dir=max(y_dir); 
        motion_params(id).videos(exp).y_dir_max= maxs_y_dir;
        maxs_y_dir=[]; y_dir=[];
        max_y_dir_arr=[max_y_dir_arr; motion_params(id).videos(exp).y_dir_max];

        maxs_z_pos=max(z_pos); 
        motion_params(id).videos(exp).z_pos_max= maxs_z_pos;
        maxs_z_pos=[]; z_pos=[];
        max_z_pos_arr=[max_z_pos_arr; motion_params(id).videos(exp).z_pos_max];

        maxs_z_neg=max(z_neg); 
        motion_params(id).videos(exp).z_neg_max= maxs_z_neg;
        maxs_z_neg=[]; z_neg=[];
        max_z_neg_arr=[max_z_neg_arr; motion_params(id).videos(exp).z_neg_max];

        maxs_z_dir=max(z_dir); 
        motion_params(id).videos(exp).z_dir_max= maxs_z_dir;
        maxs_z_dir=[]; z_dir=[];
        max_z_dir_arr=[max_z_dir_arr; motion_params(id).videos(exp).z_dir_max];

        maxs_coord_eucl_dif=max(coord_eucl_dif);
        motion_params(id).videos(exp).coord_eucl_dif_max= maxs_coord_eucl_dif;
        maxs_coord_eucl_dif=[]; coord_eucl_dif=[];
        max_coord_eucl_dif_arr=[max_coord_eucl_dif_arr; motion_params(id).videos(exp).coord_eucl_dif_max]; 

    end
    motion_params(id).max_rot_arr=max_rot_arr;
    max_rot=max(max_rot_arr);
    motion_params(id).max_rot=max_rot;
    max_rot_arr=[];

    motion_params(id).max_trans_arr=max_trans_arr;
    max_trans=max(max_trans_arr);
    motion_params(id).max_trans=max_trans;
    max_trans_arr=[];

    motion_params(id).max_x_pos_arr=max_x_pos_arr;
    max_x_pos=max(max_x_pos_arr); max_x_pos_arr=[];
    motion_params(id).max_x_pos=max_x_pos;
    motion_params(id).max_x_neg_arr=max_x_neg_arr;
    max_x_neg=max(max_x_neg_arr); max_x_neg_arr=[];
    motion_params(id).max_x_neg=max_x_neg;
    motion_params(id).max_x_dir_arr=max_x_dir_arr;
    max_x_dir=max(max_x_dir_arr); max_x_dir_arr=[];
    motion_params(id).max_x_dir=max_x_dir;

    motion_params(id).max_y_pos_arr=max_y_pos_arr;
    max_y_pos=max(max_y_pos_arr); max_y_pos_arr=[];
    motion_params(id).max_y_pos=max_y_pos;
    motion_params(id).max_y_neg_arr=max_y_neg_arr;
    max_y_neg=max(max_y_neg_arr); max_y_neg_arr=[];
    motion_params(id).max_y_neg=max_y_neg;
    motion_params(id).max_y_dir_arr=max_y_dir_arr;
    max_y_dir=max(max_y_dir_arr); max_y_dir_arr=[];
    motion_params(id).max_y_dir=max_y_dir;

    motion_params(id).max_z_pos_arr=max_z_pos_arr;
    max_z_pos=max(max_z_pos_arr); max_z_pos_arr=[];
    motion_params(id).max_z_pos=max_z_pos;
    motion_params(id).max_z_neg_arr=max_z_neg_arr;
    max_z_neg=max(max_z_neg_arr); max_z_neg_arr=[];
    motion_params(id).max_z_neg=max_z_neg;
    motion_params(id).max_z_dir_arr=max_z_dir_arr;
    max_z_dir=max(max_z_dir_arr); max_z_dir_arr=[];
    motion_params(id).max_z_dir=max_z_dir;

    motion_params(id).max_coord_eucl_dif_arr=max_coord_eucl_dif_arr;
    max_coord_eucl_dif=max(max_coord_eucl_dif_arr); max_coord_eucl_dif_arr=[];
    motion_params(id).max_coord_eucl_dif=max_coord_eucl_dif;

    for vid=1:length(motion_params(id).videos)
        for col=1:length(motion_params(id).max_rot)
            normed_rot_mat(col,:)=...
                motion_params(id).videos(vid).rot_vect(col,:)/max_rot(col);
        end
        motion_params(id).videos(vid).normed_rot_mat=normed_rot_mat;
        normed_rot_mat=[];

        for col=1:length(motion_params(id).max_trans)
            normed_trans_mat(col,:)=...
                motion_params(id).videos(vid).trans_vect(col,:)/max_trans(col);
        end
        motion_params(id).videos(vid).normed_trans_mat=normed_trans_mat;
        normed_trans_mat=[];
        for col=1:length(motion_params(id).max_x_pos)
            normed_x_pos_mat(col,:)=...
                motion_params(id).videos(vid).x_pos(:,col)/max_x_pos(col);
        end
        motion_params(id).videos(vid).normed_x_pos_mat=normed_x_pos_mat;
        normed_x_pos_mat=[];

        for col=1:length(motion_params(id).max_x_neg)
            normed_x_neg_mat(col,:)=...
                motion_params(id).videos(vid).x_neg(:,col)/max_x_neg(col);
        end
        motion_params(id).videos(vid).normed_x_neg_mat=normed_x_neg_mat;
        normed_x_neg_mat=[];

        for col=1:length(motion_params(id).max_x_dir)
            normed_x_dir_mat(col,:)=...
                motion_params(id).videos(vid).x_dir(:,col)/max_x_dir(col);
        end
        motion_params(id).videos(vid).normed_x_dir_mat=normed_x_dir_mat;
        normed_x_dir_mat=[];

        for col=1:length(motion_params(id).max_y_pos)
            normed_y_pos_mat(col,:)=...
                motion_params(id).videos(vid).y_pos(:,col)/max_y_pos(col);
        end
        motion_params(id).videos(vid).normed_y_pos_mat=normed_y_pos_mat;
        normed_y_pos_mat=[];

        for col=1:length(motion_params(id).max_y_neg)
            normed_y_neg_mat(col,:)=...
                motion_params(id).videos(vid).y_neg(:,col)/max_y_neg(col);
        end
        motion_params(id).videos(vid).normed_y_neg_mat=normed_y_neg_mat;
        normed_y_neg_mat=[];

        for col=1:length(motion_params(id).max_y_dir)
            normed_y_dir_mat(col,:)=...
                motion_params(id).videos(vid).y_dir(:,col)/max_y_dir(col);
        end
        motion_params(id).videos(vid).normed_y_dir_mat=normed_y_dir_mat;
        normed_y_dir_mat=[];

        for col=1:length(motion_params(id).max_z_pos)
            normed_z_pos_mat(col,:)=...
                motion_params(id).videos(vid).z_pos(:,col)/max_z_pos(col);
        end
        motion_params(id).videos(vid).normed_z_pos_mat=normed_z_pos_mat;
        normed_z_pos_mat=[];

        for col=1:length(motion_params(id).max_z_neg)
            normed_z_neg_mat(col,:)=...
                motion_params(id).videos(vid).z_neg(:,col)/max_z_neg(col);
        end
        motion_params(id).videos(vid).normed_z_neg_mat=normed_z_neg_mat;
        normed_z_neg_mat=[];

        for col=1:length(motion_params(id).max_z_dir)
            normed_z_dir_mat(col,:)=...
                motion_params(id).videos(vid).z_dir(:,col)/max_z_dir(col);
        end
        motion_params(id).videos(vid).normed_z_dir_mat=normed_z_dir_mat;
        normed_z_dir_mat=[];

        for col=1:length(motion_params(id).max_coord_eucl_dif)
            normed_coord_eucl_dif_mat(col,:)=...
                motion_params(id).videos(vid).coord_eucl_dif(:,col)/max_coord_eucl_dif(col);
        end
        motion_params(id).videos(vid).normed_coord_eucl_dif_mat=normed_coord_eucl_dif_mat;
        normed_coord_eucl_dif_mat=[];
    end
end
save motion_params motion_params
