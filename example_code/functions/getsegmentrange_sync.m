%% function to obtain sample range to load given a particular datetime range
% You basically convert a time range in datetime format to a particular
% sample range of certain files
%
% [start_id,stop_id,start_offset,stop_offset,timestamps_num] = getsegmentrange_sync(pulses,length_files,WavDatetime,start_time,stop_time)
% Input:
%	pulses - cell containing index of pulses for each file (acquired by
%	'get_time_sync_info.m'
%	length_files - vector containing the length of each file (acquired by
%	'get_time_sync_info.m'
%	WavDatetime - Datetime of each wav file (acquired by
%	'get_time_sync_info.m'
%	start_time - start time in de datetime format
%   stop_time - stop time in datetime format
% Output
%	start_id - start index of filelist
%	stop_id - stop index of filelist
%	start_offset - sample offset in file with start_id
%	stop_offset - sample offset in file with start_id
%   timestamps_num - timestamps in datenum format referring to the samples
%   between start_id+startoffset and stop_id+stop_offset
%
% Authors: Gert Dekkers / KU Leuven


function [start_id,stop_id,start_offset,stop_offset,timestamps_num] = getsegmentrange_sync(pulses,length_files,WavDatetime,start_time,stop_time)
    %% Get start and stop indices  
    tmp_ids = find(WavDatetime<=start_time); start_id = tmp_ids(end)-1; %start file
    tmp_ids = find(WavDatetime<=stop_time); stop_id = tmp_ids(end)+1; %stop file
    % cumsum sync pulses to obtain seconds<>samples
    fscs = cumsum([0; length_files(start_id:stop_id-1)]);
    sync_pulses = [];
    for ex=start_id:stop_id 
        sync_pulses = [sync_pulses; pulses{ex}+fscs(ex-start_id+1)];% sync
    end
    % only keep data between secs
    start_offset_in = sync_pulses(1);
    sync_pulses = sync_pulses-sync_pulses(1)+1;
    data_start_time = datetime(datestr(WavDatetime(start_id),'yyyy-mm-dd HH:MM:SS'))+1*seconds;
    % obtain timestamps for each sample
    timestamps_num = datenum(data_start_time);
    for i=1:length(sync_pulses)-1
        timestamps_num(sync_pulses(i):sync_pulses(i+1),1) = linspace(timestamps_num(end),timestamps_num(end)+datenum(1*seconds),sync_pulses(i+1)-sync_pulses(i)+1);
    end
    % get start/stop + change
    [~,start_offset] = min(abs(timestamps_num-datenum(start_time))); %start
    [~,stop_offset] = min(abs(timestamps_num-datenum(stop_time))); %stop
    timestamps_num = timestamps_num(start_offset:stop_offset);
    start_offset = start_offset+start_offset_in;
    stop_offset = stop_offset+start_offset_in;
    % repick start/stop-id/offsets
    prev_ids_start = find(fscs<start_offset);
    prev_ids_stop = find(fscs<stop_offset);
    %if (start_id+prev_ids_start(end)-1)~=(start_id+1), error; end; %sanity check
    %if (start_id+prev_ids_stop(end)-1)~=(stop_id-1), error; end; %sanity check
    stop_id = start_id+prev_ids_stop(end)-1; %new_stop_id
    start_id = start_id+prev_ids_start(end)-1; %new_start_id
    start_offset = start_offset-fscs(prev_ids_start(end))+1;
    stop_offset = stop_offset-fscs(prev_ids_stop(end))+1;
end

