%% Example code to look at the data or to simply reannotate in case of errors
%
% This is a code to perform some data exploration (listening, label check)
% and/or the (re-)annotate the data. You can choose a particular sensor
% node/mic to view the data from and explore it in a step by step basis
% (window with a stepsize). You can choose to only look at transitions, a
% particular set of class labels, from a certain startindex (to start where you
% left of) and start from a particular session id of interest (this id
% refers to the x'th row in the label file).
%
% Author: Gert Dekkers / KU Leuven

clc; clear;
addpath(fullfile('functions'));

%% Inits
node_id = 13 ; % nodes to use for annotation
mic_id = 1; % microphone indice to use for annotation
windowsize = 40; % [s] analysis window
stepsize = 35; % [s] step size of window
transitions = 1; % show only segments with transitions (in case you want to readjust/check a transition)
class_to_anno = {'all'}; % classes to annotate 'all' or list of multiple classes
startindex = 0; % index to start where left off (row in annotation file)
id_of_interest = 0; %id of interest to start from
save_anno = 1; % save or not save the annotation

%% Dir
if ispc
    basedatadir = '\\Duke.edu.khk.be\SoundData2\SINSMol\data_public\Original\audio';
    basesavedir = '\\Duke.edu.khk.be\SoundData2\SINSMol\data_public\Segmented\audio';
else
    basedatadir = '/media/SoundData2/SINSMol/data_public/Original/audio';
    basesavedir = '/media/SoundData2/SINSMol/data_public/Segmented/audio';
end

%% Inits
% load labels
annodir = fullfile('..','annotation','labels.csv'); % annotation dir
str_anno = readCSV(annodir,3); % get annotation
dt_anno = [datetime(datevec(str_anno(:,2))) datetime(datevec(str_anno(:,3)))]; % matlab datatime objects
all_class = unique(str_anno(:,1)); % unique class strings
% resort
[~,inds] = sort(dt_anno(:,1));
dt_anno = dt_anno(inds,:);
str_anno = str_anno(inds,:);
% keep orig for check
dt_anno_orig = dt_anno;
str_anno_orig = str_anno;
% reduced anno list based on labels to annotate
keep_vect = zeros(length(str_anno),1);
for k=1:length(class_to_anno)
    keep_vect = keep_vect+(strcmp(str_anno(:,1),class_to_anno{k})+ones(length(str_anno),1)*strcmp(class_to_anno{k},'all'));
end
red_str_anno = str_anno(find(keep_vect),:);
red_dt_anno = dt_anno(find(keep_vect),:);
% start stop values
dur = dt_anno(end,2)-dt_anno(1,1);
nrframes = floor((dur-(windowsize*seconds))./(stepsize*seconds)+1);
% load some shizzle
load(fullfile('other',['WavTimestamps_Node' num2str(node_id)]));
load(fullfile('other',['Pulse_samples_Node' num2str(node_id)]));
% init
start_time = dt_anno(1,1)+startindex*stepsize*seconds; stop_time = dt_anno(1,1)+startindex*stepsize*seconds+windowsize*seconds;
% save each frame
display(['Processing ' num2str(nrframes) ' segments']);
for t=startindex:nrframes
    % check in class to analyse
    class_check1 = find(sum(((red_dt_anno>=start_time)&(red_dt_anno<=stop_time)),2)); % labels which are partially overlapping
    class_check2 = find((red_dt_anno(:,1)<=start_time)&(red_dt_anno(:,2)>=stop_time)); % labels which are full overlapping
    
    %% ToDo:
    %% only show transitions for selected classes!!    
    if (~isempty(class_check1) || (~isempty(class_check2)&&~transitions)) && sum([class_check1;class_check2]>=id_of_interest)>0
        % start stop (in case of resampling, provide some samples before and after to remove edge effects)
        [start_id,stop_id,start_offset,stop_offset,timestamps_num] = getsegmentrange_sync(pulses,length_files,WavDatetime,start_time,stop_time);
        %display(['Boundaries: ' datestr(datetime(timestamps_num(1),'ConvertFrom','datenum'),'yyyy-mm-dd HH:MM:SS.FFF') ' - ' datestr(datetime(timestamps_num(end),'ConvertFrom','datenum'),'yyyy-mm-dd HH:MM:SS.FFF')])
        display(['Processing ' num2str(t) '/' num2str(nrframes) ' ~ ' datestr(start_time,'yyyy-mm-dd HH:MM:SS.FFF') ' till ' datestr(stop_time,'yyyy-mm-dd HH:MM:SS.FFF') ' - min. id ' num2str(max([class_check1;class_check2])) ' - max. id ' num2str(max([class_check1;class_check2]))])
        % get label-wise information
        indices_part = find(sum(((dt_anno>=start_time)&(dt_anno<=stop_time)),2)); % labels which are partially overlapping
        indices_full = find((dt_anno(:,1)<=start_time)&(dt_anno(:,2)>=stop_time)); % labels which are full overlapping
        indices = [indices_part; indices_full];
        tmp_str_anno = str_anno(indices,:); % class strings
        tmp_dt_anno = dt_anno(indices,:); % datetimes
        tmp_dn_anno = datenum(tmp_dt_anno); % datenums
        tmp_all_class = unique(tmp_str_anno(:,1)); % all classes

        % is it a class I want to reannotate?
%         proceed_class = 0;
%         for k=1:length(class_to_anno)
%             if sum(strcmp(class_to_anno{k},tmp_all_class))>0 || sum(strcmp(class_to_anno{k},'all'))>0, proceed_class = 1; end;
%         end
        proceed_class = 1;

        % is their a transition for a particular class?
%         proceed_transition = 0;
%         if  ~isempty(indices_part) || ~transitions
%             proceed_transition = 1;
%         end
        proceed_transition = 1;
        
        if proceed_class && proceed_transition % if checks pass, annotate
            %% Get data 
            % inits
            datadir = fullfile(basedatadir,['Node' num2str(node_id)],'audio'); 
            % load data
            if start_id==stop_id %in same file
                % get data
                [data, fs] = audioread(fullfile(datadir,WavFiles{start_id}));
                data = data(start_offset:min(stop_offset,size(data,1)),mic_id); 
            else
                [data, fs] = audioread(fullfile(datadir,WavFiles{start_id}));
                data = data(start_offset:end,mic_id);
                for e2=start_id+1:stop_id-1 % load in-between files
                    [data_tmp, ~] = audioread(fullfile(datadir,WavFiles{e2}));
                    data = [data; data_tmp(:,mic_id)];
                end
                [data_tmp, ~] = audioread(fullfile(datadir,WavFiles{stop_id})); %load final file
                data = [data; data_tmp(1:stop_offset,mic_id)];
            end
            %% Annotate
            % get labelvector
            labelvector = zeros(length(data),length(tmp_all_class));
            for k=1:size(tmp_str_anno,1) %for every annotation
                %if (timestamps_num(1)-tmp_dn_anno(k,2))<0 && (timestamps_num(end)-tmp_dn_anno(k,1))>0 % sanity check, if inside the border
                [~,id_change1] = min(abs(timestamps_num-tmp_dn_anno(k,1))); %start
                [~,id_change2] = min(abs(timestamps_num-tmp_dn_anno(k,2))); %stop
                
%                 display(['Ref: ' datestr(datetime(timestamps_num(id_change1),'ConvertFrom','datenum'),'yyyy-mm-dd HH:MM:SS.FFF')]);
%                 display(['Start value: ' datestr(datetime(tmp_dt_anno(k,1)),'yyyy-mm-dd HH:MM:SS.FFF')]);
%                 %datestr(datetime(timestamps_num(id_change1),'ConvertFrom','datenum')-tmp_dt_anno(k,1),'yyyy-mm-dd HH:MM:SS.FFF')
%                 
%                 display(['Ref: ' datestr(datetime(timestamps_num(id_change2),'ConvertFrom','datenum'),'yyyy-mm-dd HH:MM:SS.FFF')]);
%                 display(['Stop value: ' datestr(datetime(tmp_dt_anno(k,2)),'yyyy-mm-dd HH:MM:SS.FFF')]);
%                 %datestr(datetime(timestamps_num(id_change2),'ConvertFrom','datenum')-tmp_dt_anno(k,2),'yyyy-mm-dd HH:MM:SS.FFF')
                
                labelvector(id_change1:id_change2,strcmp(tmp_all_class,tmp_str_anno{k,1})) = 1;
                %end
            end        
            % Re-annotate       
            labelvector_new = annotateAudio(data(:,1),fs,tmp_all_class,labelvector,'none');
            display(['Changed ' num2str(sum(sum(labelvector-labelvector_new))/16000) ' seconds of data.'])
            %% Convert to start stop date time representation
            [tmp_dt_anno_new,tmp_str_anno_new,~,tmp_all_class_new,edges] = LabelVec2StartStop_sync(labelvector_new,timestamps_num,tmp_all_class,fs);
            
            %% Put into input annotation
            for k=1:length(tmp_all_class_new)
                edges_vect = repmat(strcmp(tmp_str_anno_new(:,1),tmp_all_class_new{k}),1,2) & edges; %edges matrix
                if sum(edges_vect(:,1))>1 || sum(edges_vect(:,2))>1, error; end; %sanity check
                low_val = min(tmp_dt_anno(strcmp(tmp_str_anno(:,1),tmp_all_class_new{k}),1)); %high/low val used for replacement
                high_val = max(tmp_dt_anno(strcmp(tmp_str_anno(:,1),tmp_all_class_new{k}),2));
                
                % replace edges
                if sum(edges_vect(:,1))==1
                    tmp_dt_anno_new(edges_vect(:,1),1) = low_val; 
                    tmp_str_anno_new{edges_vect(:,1),2} = datestr(low_val,'yyyy-mm-dd HH:MM:SS.FFF');
                end;
                if sum(edges_vect(:,2))==1
                    tmp_dt_anno_new(edges_vect(:,2),2) = high_val; 
                    tmp_str_anno_new{edges_vect(:,2),3} = datestr(high_val,'yyyy-mm-dd HH:MM:SS.FFF');
                end;
            end
            %tmp_str_anno
            %tmp_str_anno_new
            % remove old and add to csv file
            str_anno(indices,:) = [];
            dt_anno(indices,:) = [];
            str_anno = [str_anno; tmp_str_anno_new];
            dt_anno = [dt_anno; tmp_dt_anno_new];
            % resort
            [~,inds] = sort(dt_anno(:,1));
            str_anno = str_anno(inds,:);
            dt_anno = [datetime(datevec(str_anno(:,2))) datetime(datevec(str_anno(:,3)))]; % matlab datatime objects
            % Save
            if save_anno
                writeCSV(annodir,[{'Class','Start time','Stop time'}; str_anno]);
            end
        end
    end
    % update start and stop time for next iteration
    start_time = start_time+stepsize*seconds; stop_time = stop_time+stepsize*seconds;
end
