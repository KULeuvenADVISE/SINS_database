%% function to go from the SINS database filename to date representation
%
% [year,month,day,hour,min,sec,msec] = filename2time(filename,str2nm)
% Input:
%	filename - filename
%   str2nm - bool, 1: convert to numeric, 2: keep as string
% Output
%	year - obvious
%   ...
%   msec
%
% Authors: Gert Dekkers / KU Leuven

function [year,month,day,hour,min,sec,msec] = filename2time(filename,str2nm)
    inds = strfind(filename,'_');
    year = filename(inds(1)+1:inds(1)+4); %year
    month = filename(inds(1)+5:inds(1)+6); %month
    day = filename(inds(1)+7:inds(1)+8); %day
    hour = filename(inds(2)+1:inds(2)+2); %hour
    min =  filename(inds(2)+3:inds(2)+4); %min
    sec = filename(inds(2)+5:inds(2)+6); %sec
    msec = filename(inds(3)+1:inds(4)-1); %sec
    if str2nm
        year = str2double(year); month = str2double(month); day = str2double(day); hour = str2double(hour); min = str2double(min); sec = str2double(sec); msec = str2double(msec);  
    end
end