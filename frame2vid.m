%% MH Recordings 
avatars={'Cooper','Ettore','Lena'};
expressions={'Amaze-B' 'Anger-B' 'Fear-B' 'Happy-B' 'Sad-B'}; %except for 'Face-ROM'
for i=1:length(avatars)
    curID=avatars{i};
    for j=1:length(expressions)
        curExp=expressions{j};
        input_dir=['C:\Users\hilal\Desktop\JLU-Dobs\MetaHuman Recordings\Trimmed Videos\' curID '\Frames\' curExp];
        cd(input_dir)
        mkdir('Video')
        output_dir=[input_dir '\Video'];
        output_vid=[curID '_' curExp];
        videoOutput = VideoWriter(output_vid) ;
        videoOutput.FrameRate=20; %default=30
        open(videoOutput)
        for curFrame=1:length(dir('*.png'))
            frameImg=image(imread(sprintf('Frame %4.4d.png', curFrame)));
            frame = getframe(gcf);
            writeVideo(videoOutput,frame.cdata)
        end
        close(videoOutput)
    end
end
%% MPI Large Database
output_dir=['C:\Users\hilal\Desktop\JLU-Dobs\MPI_large_database\'];
subj=['silf'];
expressions={'agree_considered', 'agree_continue', 'agree_pure',};
cd([output_dir subj])
curExp=expressions{3};
png_name=[subj '_' curExp '_001.png'];
png_dir=which(png_name);
cd(png_dir)

output_vid=[subj '_' curExp];
videoOutput = VideoWriter(output_vid) ;
videoOutput.FrameRate=30; %default=30
open(videoOutput)
for curFrame=1:length(dir('*.png'))
    frameImg=image(imread(sprintf('silf_agree_continue_%3.3d.png', curFrame)));
    frame = getframe(gcf);
    writeVideo(videoOutput,frame.cdata)
end
close(videoOutput)