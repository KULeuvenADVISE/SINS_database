%% Example code for segmenting the dataset
%
% Segmenting is performed based on the sync timestamps acquired by
% "get_time_sync_info.m". The code selects a time
% segment of 10 seconds, but not each sensor node has the sampling
% frequency (clock drifts/offsets). You can optionally select "resampling" 
% in case you want output examples to match a certain size. Also you can
% select whether you use segments that have more than one label (e.g.
% during activity transition) and what the time reference is of the label.
%
% Besides segmenting it also provides the labels accompagnied by those
% segments. 
%
% Author: Gert Dekkers / KU Leuven

clc; clear;
addpath(fullfile('functions'));

%% Inits
node_ids = [1 2 3 4 6 7 8]; % nodes to process
mic_ids = [1 2 3 4]; % microphone indices to use
windowsize = 10; % s
stepsize = 10; % s
resampling = 1; % resample to match fs_ref?
fs_ref = 16000; % reference sampling frequency
allow_overlap = 'true'; % In a particular window, multiple labels can occur. Use examples containing two labels or not?
label_causality = windowsize/2; % reference point of label (0=causal)
room = 'living'; %only relevant for the labels (segments should be identical)

%% Dir
if ispc
    basedatadir = '\\Duke.edu.khk.be\SoundData2\SINSMol\data_public\Original\audio';
    basesavedir = '\\Duke.edu.khk.be\SoundData2\SINSMol\data_public\Segmented\audio';
else
    basedatadir = '/media/SoundData2/SINSMol/data_public/Original/audio';
    basesavedir = '/media/SoundData2/SINSMol/data_public/Segmented/audio';
end
labelsavedir = fullfile('..','annotation');

%% Inits
% load labels
annodir = fullfile('..','annotation',[room '_labels.csv']); % annotation dir
str_anno = readCSV(annodir,3); % get annotation
dt_anno = [datetime(datevec(str_anno(:,2))) datetime(datevec(str_anno(:,3)))]; % matlab datatime objects
all_class = unique(str_anno(:,1)); % unique class strings
% start stop values
dur = dt_anno(end,2)-dt_anno(1,1);
nrframes = floor((dur-(windowsize*seconds))./(stepsize*seconds)+1);

%% Loop to obtain data
for n=node_ids
    % dir
    load(fullfile('other',['WavTimestamps_Node' num2str(n)]));
    load(fullfile('other',['Pulse_samples_Node' num2str(n)]));
    % init
    start_time = dt_anno(1,1); stop_time = dt_anno(1,1)+windowsize*seconds;
    
    % save each frame
    display(['Processing ' num2str(nrframes) ' segments']);
    for t=1:nrframes
       
        %% Get data and save
        % start stop (in case of resampling, provide some samples before and after to remove edge effects)
        [start_id,stop_id,start_offset,stop_offset] = getsegmentrange_sync(pulses,length_files,WavDatetime,start_time-resampling*seconds,stop_time+resampling*seconds);        
        % inits
        datadir = fullfile(basedatadir,['Node' num2str(n)],'audio'); 
        savedir = fullfile(basesavedir,strrep([num2str(windowsize) 's_' num2str(stepsize) 's'],'.','_'),['Node' num2str(n)]); 
        warning off; mkdir(savedir); warning off;
        savefilename = [datestr(start_time,'yyyy-mm-dd_HH-MM-SS-FFF') '_till_' datestr(stop_time,'yyyy-mm-dd_HH-MM-SS-FFF') '.wav']; %filename
        % load data
        if start_id==stop_id %in same file
            % get data
            [data, fs] = audioread(fullfile(datadir,WavFiles{start_id}));
            data = data(start_offset:min(stop_offset,size(data,1)),mic_ids); 
        else
            [data, ~] = audioread(fullfile(datadir,WavFiles{start_id}));
            data = data(start_offset:end,mic_ids);
            for e2=start_id+1:stop_id-1 % load in-between files
                [data_tmp, ~] = audioread(fullfile(datadir,WavFiles{e2}));
                data = [data; data_tmp(:,mic_ids)];
            end
            [data_tmp, ~] = audioread(fullfile(datadir,WavFiles{stop_id})); %load final file
            data = [data; data_tmp(1:stop_offset,mic_ids)];
        end
        % resample
        if resampling %do resampling
            data_tmp = data;
            ref_size = fs_ref*(windowsize+2*resampling);
            %figure(1);
            %subplot(2,1,1); plot(data(round(length(data)/(windowsize+2*resampling)):round(length(data)/(windowsize+2*resampling))+round(windowsize*length(data)/(windowsize+2*resampling)),:));
            [sn, sk] = rat(ref_size/length(data));
            data = resample(data,sn,sk); % resample
            if length(data)~=ref_size %if doesnt match exactly, linearly interpolate to obtain correct size
                data = interp1(linspace(0,ref_size-1,length(data))',data,(0:1:ref_size-1)');
            end; 
            data = data(resampling*fs_ref:resampling*fs_ref+fs_ref*(windowsize)-1,:);
            %subplot(2,1,2); plot(data);
        end
        % save
        audiowrite(fullfile(savedir,savefilename),data,fs_ref);
        % update start and stop time for next iteration
        start_time = start_time+stepsize*seconds; stop_time = stop_time+stepsize*seconds;
        % print
        display(['Processed ' num2str(t) '/' num2str(nrframes) ' of Node ' num2str(n)]);
    end
end

%% Loop to obtain labels for the acquired segments
% init
start_time = dt_anno(1,1); stop_time = dt_anno(1,1)+windowsize*seconds;
% save each frame
display(['Processing ' num2str(nrframes) ' segments']);
for t=1:nrframes
    %% Get labels
    % get label
    labeltime = stop_time-label_causality*seconds;
    label_index = find(((dt_anno(:,1)<=labeltime)&(dt_anno(:,2)>=labeltime))); %on transitions there are two indices ...
    % keep
    label_info{t,1} = [datestr(start_time,'yyyy-mm-dd_HH-MM-SS-FFF') '_till_' datestr(stop_time,'yyyy-mm-dd_HH-MM-SS-FFF') '.wav']; %filename
    label_info{t,2} = str_anno{label_index,1}; %label str      
    label_info{t,3} = label_index; % session index (keep together in folds!)
    % update start and stop time for next iteration
    start_time = start_time+stepsize*seconds; stop_time = stop_time+stepsize*seconds;
end
% save
save(fullfile(labelsavedir,[room '_segment_' strrep([num2str(windowsize) 's_' num2str(stepsize) 's'],'.','_') 'labels.mat']),'label_info');






