%% read a CSV file, delimiter: ';'
%
% function output = readCSV(filestr, nr_columns)
% Input:
%	filestr - file location
%	nr_columns - amount of columns
% Output
%	output - cell containing the data
%
% Authors: Gert Dekkers / KU Leuven

function output = readCSV(filestr, nr_columns)
    fid = fopen(filestr); %open csv file
    tmp_read = textscan(fid,repmat('%s ',1, nr_columns),'Delimiter',';','HeaderLines',1); %read data except header
    output = [];
    for c=1:nr_columns
        output = [output tmp_read{c}];
    end
    fclose(fid);
end