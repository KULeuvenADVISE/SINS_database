%% function to convert labelvector to datetime vector to save as CSV file
% This creates datetime labels based on a annotation matrix by using the
% absolute datenum timings of the labelvector.
% This is the 'sync' variant of 'LabelVec2StartStop'. So this can be used
% for annotating purposes of the dataset.
%
% [dt_label,str_label,samp_label,labels,edges_label] = LabelVec2StartStop_sync(labelvector,time_offset,labels,fs)
% Input:
%	labelvector - [sample x labels] matrix (1/0 active/not active class)
%	timesamples_num - datenum values for each sample in the labelvector
%	labels - cell with labels (matching the columns of labelvector)
% Output
%	dt_label - datetime matrix with 2 columbs 'Start time' and 'stop time'
%	str_label - cell with 3 columns 'Class,'Start time','Stop time' [string]
%	samp_label - Same as dt_label, but then in samples
%	labels - unique labels
%   edges_label - gives insight in which label is still active at edge (is
%   used for later processing @ anno_reannotator.m
%
% Authors: Gert Dekkers / KU Leuven

function [dt_label,str_label,samp_label,labels,edges_label] = LabelVec2StartStop_sync(labelvector,timesamples_num,labels)
%% Convert to start stop date time representation
str_label = []; dt_label = []; samp_label = []; edges_label = [];
[dt_label_sep,str_label_sep,samp_label_sep,edges_sep] = deal(cell(length(labels),1));
labelvector = [labelvector; zeros(1,size(labelvector,2))];
trans = filter([1 -1],1,labelvector); %transitions
for k=1:length(labels) %for every class
    % obtain start stops
    start_samps = find(trans(:,k)==1);
    stop_samps = find(trans(:,k)==-1)-1;
    start = datetime(time_offset(start_samps),'ConvertFrom','datenum');
    stop = datetime(time_offset(stop_samps),'ConvertFrom','datenum');    
    samp_label_sep{k,1} = [start_samps stop_samps];
    dt_label_sep{k,1} = [start stop];
    edges_sep{k,1} = [start_samps==1 stop_samps==(length(labelvector)-1)];
    str_label_sep{k,1} = [repmat({labels{k}},size(dt_label_sep{k,1},1),1) ... %labelnames
                            mat2cell(datestr(dt_label_sep{k,1}(:,1),'yyyy-mm-dd HH:MM:SS.FFF'),ones(size(dt_label_sep{k,1},1),1),23) ... %start stop
                                mat2cell(datestr(dt_label_sep{k,1}(:,2),'yyyy-mm-dd HH:MM:SS.FFF'),ones(size(dt_label_sep{k,1},1),1),23)]; %start stop
    % put together for all classes
    if k>1, dt_label = [dt_label; dt_label_sep{k,1}]; else dt_label = dt_label_sep{k,1}; end;
    if k>1, samp_label = [samp_label; samp_label_sep{k,1}]; else samp_label = samp_label_sep{k,1}; end;
    if k>1, edges_label = [edges_label; edges_sep{k,1}]; else edges_label = edges_sep{k,1}; end;
    str_label = [str_label; str_label_sep{k,1}];
end
[~,inds] = sort(dt_label(:,1));
dt_label = dt_label(inds,:);
str_label = str_label(inds,:);
samp_label = samp_label(inds,:);
edges_label = edges_label(inds,:);
labels = unique(str_label(:,1));
end

