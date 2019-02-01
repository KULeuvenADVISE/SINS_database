%% function to convert labelvector to datetime vector to save as CSV file
% This creates datetime labels based on a annotation matrix by assuming a
% certain sampling frequency
%
% [dt_label,str_label,samp_label,labels] = LabelVec2StartStop(labelvector,time_offset,labels,fs)
% Input:
%	labelvector - [sample x labels] matrix (1/0 active/not active class)
%	time_offset - time offset of the 0th sample of the labelvector
%	labels - cell with labels (matching the columns of labelvector)
%	fs - sampling frequency of labelvector
% Output
%	dt_label - datetime matrix with 2 columbs 'Start time' and 'stop time'
%	str_label - cell with 3 columns 'Class,'Start time','Stop time' [string]
%	samp_label - Same as dt_label, but then in samples
%	labels - unique labels
%
% Authors: Gert Dekkers / KU Leuven

function [dt_label,str_label,samp_label,labels] = LabelVec2StartStop(labelvector,time_offset,labels,fs)
%% Convert to start stop date time representation
str_label = []; dt_label = []; samp_label = [];
[dt_label_sep,str_label_sep] = deal(cell(length(labels),1));
labelvector = [labelvector; zeros(1,size(labelvector,2))]; %add zeros for negative
trans = filter([1 -1],1,labelvector); %transitions
for k=1:length(labels) %for every class
    % obtain start stops
    start_samps = find(trans(:,k)==1);
    stop_samps = find(trans(:,k)==-1)-1;
    start = (start_samps/fs * seconds) + time_offset;
    stop = (stop_samps/fs * seconds) + time_offset;    
    samp_label_sep{k,1} = [start_samps stop_samps];
    dt_label_sep{k,1} = [start stop];
    str_label_sep{k,1} = [repmat({labels{k}},size(dt_label_sep{k,1},1),1) ... %labelnames
                            mat2cell(datestr(dt_label_sep{k,1}(:,1),'yyyy-mm-dd HH:MM:SS.FFF'),ones(size(dt_label_sep{k,1},1),1),23) ... %start stop
                                mat2cell(datestr(dt_label_sep{k,1}(:,2),'yyyy-mm-dd HH:MM:SS.FFF'),ones(size(dt_label_sep{k,1},1),1),23)]; %start stop
    % put together for all classes
    if k>1, dt_label = [dt_label; dt_label_sep{k,1}]; else dt_label = dt_label_sep{k,1}; end;
    if k>1, samp_label = [samp_label; samp_label_sep{k,1}]; else samp_label = samp_label_sep{k,1}; end;
    str_label = [str_label; str_label_sep{k,1}];
end
[~,inds] = sort(dt_label(:,1));
dt_label = dt_label(inds,:);
str_label = str_label(inds,:);
samp_label = samp_label(inds,:);
labels = str_label(:,1);
end

