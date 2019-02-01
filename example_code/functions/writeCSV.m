%% write a CSV file, delimiter: ';'
%
% function output = readCSV(filestr, nr_columns)
% Input:
%	file - file location
%	txt_cell - cell to save as .csv
%
% Authors: Gert Dekkers / KU Leuven

function writeCSV(file, txt_cell)
    % text openen om te schrijven
    fid = fopen(file, 'w');
    txt = '';
    for i = 1:size(txt_cell,1)
        for j = 1:size(txt_cell,2)-1
            txt = [txt txt_cell{i,j} ';'];
        end
        txt = [txt txt_cell{i,j+1} '\n'];
    end
    fprintf(fid,txt);
    fclose(fid);
end