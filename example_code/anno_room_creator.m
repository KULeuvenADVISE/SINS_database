%% Example code for extracting annotation in a particular room 
%
% The annotation file consists of activity labels and room labels. Activity
% labels refer to the activity taking place and the room labels to which
% room a person is present. This code transform the original annotation
% file to a room-specific annotation file. If you want to monitor rooms
% seperately, then doing a certain activity in the bathroom is considered
% to be an 'absence' class in the living room and vice versa. This code is
% relevant if you want to test a different model in each room.
%
% Output of the code is already available in the folder 'annotation'
% it contains: 
%   - ROOM_labels.csv: for each room a specific annotation 
% and computes it based on the original label file "annotation/labels.csv"
%
% Author: Gert Dekkers / KU Leuven

clc; clear;
addpath(fullfile('functions'));

room = 'living'; % select room. Options: 'living','bathroom','wcroom','bedroom', 'hall'
% Load labels
annodir = fullfile('..','annotation','labels.csv'); % annotation dir
str_anno = readCSV(annodir,4); % get annotation
dt_anno = [datetime(datevec(str_anno(:,2))) datetime(datevec(str_anno(:,3)))]; % matlab datatime objects
all_class = unique(str_anno(:,1)); % unique class strings
% other inits 
switch room % classes to place in the 'other' class for a particular room
    case 'living', ignore = {'toilet'};
    otherwise, ignore = cell(0,0);
end%% Inits
switch room % classes to place in the 'other' class for a particular room
    case 'wcroom', other = {'visit'}; 
    case 'hall', other = {'visit','dressing','toilet'}; 
    otherwise, other = cell(0,0);
end
room_class = {'living','hall','bathroom','wcroom','bedroom'}; % all room labels

%% processing
% Convert to logical streams of resolution 10 ms
start_time = dt_anno(1,1); stop_time = dt_anno(end,2); % time boundaries 
time_acc = 50; mltp = 24*60*60*time_acc; % time accuracy
timevec = zeros(length(all_class),ceil(datenum(stop_time-start_time)*mltp)); % create time vector
for c=1:length(all_class)
    ids = find(strcmp(all_class{c},str_anno(:,1)));
    dt_anno_sub = dt_anno(ids,:);
    for v=1:size(dt_anno_sub,1)
        start_index = max(round((datenum(dt_anno_sub(v,1)-start_time))*mltp),1);
        stop_index = round((datenum(dt_anno_sub(v,2)-start_time))*mltp);
        timevec(c,start_index:stop_index) = ones(1,stop_index-start_index+1);
    end
    %display(['Class ' num2str(c) '/' num2str(length(all_class))]);
end

% living active when hall & vac active (when vac cleaning, door was open
% between hall and living area)
if strcmp('living',room)
    hall_id = find(strcmp(all_class,'hall')); %room class
    liv_id = find(strcmp(all_class, 'living')); %room class
    vac_id = find(strcmp(all_class,'vacuumcleaner')); %room class
    timevec(liv_id, find(timevec(vac_id,:) & timevec(hall_id,:))) = 1;
end

% remove all rooms except current one
remove_ids = setdiff(1:length(room_class),find(strcmp(room_class,room))); 
for r=1:length(remove_ids)
    remove_id = find(strcmp(all_class,room_class(remove_ids(r))));
    all_class(remove_id) = []; 
    timevec(remove_id,:) = [];
end;

% add absence
room_id = find(strcmp(all_class,room));
abs_id = find(strcmp(all_class,'absence'));
% timevec(abs_id,:) = min(timevec(abs_id,:)+(~timevec(room_id,:)),1);
timevec(abs_id,:) = ~timevec(room_id,:);

% Remove classes that are active throughout 'absence' except for 'dont use'
room_id = find(strcmp(all_class,room));
abs_id = find(strcmp(all_class,'absence'));
du_id = find(strcmp(all_class,'dont use'));
timevec(setdiff(1:length(all_class),[room_id abs_id]),find(timevec(abs_id,:)==1 & timevec(du_id,:)==0)) = 0;

% add other class when room is active but no other classes
% ToDO and also room IDS!!
room_id = find(strcmp(all_class,room));
timevec(end+1,:) = timevec(room_id,:)==sum(timevec,1);
all_class{end+1} = 'other'; 

% Add classes to other
if ~isempty(other)
    for i=1:length(other)
        o_id(i,1) = find(strcmp(all_class,other{i}));
    end
    timevec(find(strcmp(all_class,'other')),:) = min(timevec(find(strcmp(all_class,'other')),:) + sum(timevec(o_id,:),1),1); %when only living is active
    all_class(o_id,:) = []; timevec(o_id,:) = [];
end

% remove everything when dont use is active
du_id = find(strcmp(all_class,'dont use')); %dont use class
timevec(setdiff(1:length(all_class),du_id),find(timevec(du_id,:))) = 0;

% toilet active when not dont use and not vacuumcleaner
if strcmp('wcroom',room)
    other_id = find(strcmp('other',all_class));
    toi_id = find(strcmp('toilet',all_class));
    timevec(toi_id, find(timevec(other_id,:))) = 1;
    timevec(other_id,:) = []; all_class(other_id) = [];
end

% there was one time someone went to the bathroom when visiting. For the
% living room area this activity should be ignored
if strcmp('living',room)
    toi_id = find(strcmp('toilet',all_class));
    timevec(toi_id, :) = 0;
end

% only keep used and relevant classes 
kept_class_id = find((sum(timevec,2)>0));
all_class = all_class(kept_class_id);
timevec = timevec(kept_class_id,:);

% remove current room label
rem_id = strcmp(all_class,room);
all_class(rem_id,:) = [];
timevec(rem_id,:) = [];
% kept_class
% figure;imagesc(timevec)

% Convert back to start stop date time representation representation sep. for each class
[dt_label,str_label] = LabelVec2StartStop(timevec',start_time,all_class,time_acc);
str_label = str_label(:,1:3); str_label = [{'Class','Start time','Stop time'};str_label];
writeCSV(fullfile('annotation',[room '_labels.csv']),str_label);
