%% Code for generating timestamps based on the interrupts each sensor node collected
%
% Each sensor node used an NTP timestamp to store the ~60s .wav files.
% Because the sync accuracy is limited for that case, we added an additional way of syncing. 
% The microcontroller responsible for the sampling of the audio also had an internal counter value that we send through. 
% This value is incremented by a clock of 48kHz. To allow for synchronization we had a reference signal connected to each microcontroller. 
% The signal caused an interrupt on all microcontrollers to reset their
% internal counter value every second. This values are available in the
% dataset under the folder "NodeX/sync". This code processes these values
% such that the timestamps of the interrupts (every second) can be used for
% roughly syncing/segmenting the data. This way an sync accuracy of +-0.5s
% can be obtained between sensor nodes. Note: microphones on a particular
% node are in sync!
%
% Output of the code is already available in the folder 'other'
% it contains: 
%   - datetime objects of each file for each node ("WavTimestamps_NodeX")
%   - Sample indices of where a sync interrupt occured ("Pulse_samples_NodeX").
%
% Author: Gert Dekkers / KU Leuven

addpath('functions');
%% Dir
if ispc
    datadir = '\\Duke.edu.khk.be\SoundData2\SINSMol\data_public\Original\audio';
else
    datadir = '/media/SoundData2/SINSMol/data_public/Original/audio';
end
savedir = 'other';
%node_ids = [1 2 3 4 6 7 8];
node_ids = 1;

%% Get timestamps
for n=node_ids
    filename = ['WavTimestamps_Node' num2str(n) '.mat'];
    if exist(fullfile(savedir,filename))~=2
    filedir = list_folder(fullfile(datadir, ['Node' num2str(n)],'audio'),'none','all');
    WavDatetime(length(filedir.filenames),1) = datetime;
    for k=1:length(filedir.filenames)
        [year,month,day,hour,min,sec,msec] = filename2time(filedir.filenames{k},1);
        WavDatetime(k,1) = datetime(datenum(year,month,day,hour,min,sec+msec/1000),'ConvertFrom','datenum');
    end
    WavFiles = filedir.filenames;
    save(fullfile(savedir,filename),'WavFiles','WavDatetime');
    display(['Obtained timestamps from Node ' num2str(n)]);
    end
end

%% Get timestamps
for n = node_ids
    filename = ['Pulse_samples_Node' num2str(n) '.mat'];
    if exist(fullfile(savedir,filename))~=2
        load(fullfile(savedir,['WavTimestamps_Node' num2str(n) '.mat']),'WavFiles','WavDatetime');
        % get average amount of clock per file
        files = size(WavFiles,1);
        pulses = cell(files,1);
        length_files = zeros(files,1);
        data_lo = [];
        for f = 1:files
            load(fullfile(datadir,['Node' num2str(n)],'sync',strrep(WavFiles{f},'_audio.wav','_sync.mat')));
            plss = filter([-1 1],1,[data_lo; sync_audio]);
            pulses{f,1} = find(plss>46000)-length(data_lo);
            length_files(f,1) = length(sync_audio);
            data_lo = sync_audio(pulses{f}(end)+1:end);
        end
        save(fullfile(savedir,filename),'pulses','length_files');
        display(['Obtained pulse sample indices from Node ' num2str(n)]);
    end
end
    
