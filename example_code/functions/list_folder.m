%% Functions to directory-list a folder (and optionally one level of subfolders) with name-checking
%
% function o = list_folder(orig_dir,type_folder,type_file,contain1,contain2)
% Input:
%	orig_dir - directiory to check
%	type_folder - string containing 'all','contain', 'select' or 'none'
%	type_file - string containing 'all','contain', 'select' or 'none'
%	contain1 - string that the folder should contain
% 	contain2 - string that the filename should contain
% Output
%	o - struct containing all folder info
%
% With 'contain' you can check for strings. With 'select' you can query to
% process a certain file/folder. With 'all' you just dir-list everything.
%
% Authors: Gert Dekkers / KU Leuven

function o = list_folder(orig_dir,type_folder,type_file,contain1,contain2)
    %% inits
    o.orig_dir = orig_dir;
    dirlist = dir(orig_dir);
    o.filenames = cell(0,0);
    o.foldernames = cell(0,0);
    filen = cell(0,0);
    foldern = cell(0,0);
    o.fulldir = cell(0,0);
    %o.fulldir{1,1} = 'Proefpersoon'; o.fulldir{1,2} = 'Filelist'; o.fulldir{1,3} = 'Fulldir'; 
    contain_file = '';
    contain_folder = '';
    
    %% checks
    %general
    if nargin < 3,
        error('Je moet minimaal de main dir, type_folder & type_file opgeven.');
    end;
    %dir options
    if ~strcmp(type_folder,'all') && ~strcmp(type_folder,'contain') && ~strcmp(type_folder,'select'),
        error('Gekozen type_folder is niet beschikbaar.');
    end
    %file options
    if ~strcmp(type_file,'all') && ~strcmp(type_file,'contain') && ~strcmp(type_file,'select'),
        error('Gekozen type_file is niet beschikbaar.');
    end
    %contain
    if strcmp(type_folder,'contain') && strcmp(type_file,'contain') && ~(nargin == 5),
        error('Er klopt iets niet met uw opgegeven argumenten bij contain1/contain2.');
    end

    %% Select contain
    if  strcmp(type_folder,'contain') && strcmp(type_file,'contain'),
        contain_folder = contain1;
        contain_file = contain2;
    elseif strcmp(type_folder,'contain'),
        contain_folder = contain1;
    elseif strcmp(type_file,'contain'),
        contain_file = contain1;
    end

    %% Check folders
    if ~strcmp(type_folder,'none'),
        for n=3:length(dirlist),
            if dirlist(n).isdir, %only folders!
                [o.foldernames, foldern] = check(dirlist(n).name,o.foldernames,foldern,type_folder,contain_folder);                
            end
        end
        dirll = length(o.foldernames);
    else
        dirll = 1;
        o.foldernames = {''};
    end   

    %% Check files
    for n=1:dirll,
        folder = fullfile(orig_dir,o.foldernames{n});
        dirfolder = dir(folder);
        dirfl = length(dirfolder);
        for k=3:dirfl,
            if dirfolder(k).isdir ~= 1, %case domotica structure
                l = size(o.fulldir,1)+1;
                [o.filenames, filen, accepted] = check(dirfolder(k).name,o.filenames,filen,type_file,contain_file);
                if accepted == 1,
                    o.fulldir{l,1} = o.foldernames{n};
                    o.fulldir{l,2} = dirfolder(k).name;
                    o.fulldir{l,3} = fullfile(folder,dirfolder(k).name);
                else
                    lol = 1;
                end
                if length(o.filenames)<size(o.fulldir,1),
                    lol = 1;
                end
            else %case patience structure where there are multiple subdirs for each pp
                subfolder = fullfile(orig_dir,o.foldernames{n},dirfolder(k).name);
                subdirfolder = dir(subfolder);
                subdirfl = length(subdirfolder);
                for s=3:subdirfl,
                    l = size(o.fulldir,1)+1;
                    stemp = fullfile(dirfolder(k).name, subdirfolder(s).name);
                    [o.filenames, filen, accepted] = check(stemp,o.filenames,filen,type_file,contain_file);
                    if accepted == 1,
                        o.fulldir{l,1} = o.foldernames{n};
                        o.fulldir{l,2} = dirfolder(k).name;
                        o.fulldir{l,3} = subdirfolder(s).name;
                        o.fulldir{l,4} = fullfile(folder,stemp);
                    end
                end
            end
        end
    end
end

function [ylist, nlist, accepted] = check(stemp,ylist,nlist,type,contain)
    result = '';
        if strcmp(type,'all'),
            result = 'y';
        elseif strcmp(type,'select'),
            display(['Wilt u ' stemp ' verwerken? (y/n) ']);
            result = input('','s');
        elseif strcmp(type,'contain'),
            test = ~isempty(strfind(stemp,contain)); %check if contains for example 'SegmentNr_'
            if test==1, result = 'y'; end;
        end

        if result == 'y',
            accepted = 1;
            ylist{length(ylist)+1,1} = stemp;    
        else
            accepted = 0;
            nlist{length(nlist)+1,1} = stemp;            
        end;
end

% function [ylist, nlist, accepted] = check(stemp,ylist,nlist,type,contain)
%     batempy = strfind(ylist,stemp);
%     batempn = strfind(nlist,stemp);
%     indexy = find(not(cellfun('isempty', batempy)));
%     indexn = find(not(cellfun('isempty', batempn)));
%     result = '';
%     if isempty(indexn)==true && isempty(indexy)==true ,
%         if strcmp(type,'all'),
%             result = 'y';
%         elseif strcmp(type,'select'),
%             display(['Wilt u ' stemp ' verwerken? (y/n) ']);
%             result = input('','s');
%         elseif strcmp(type,'contain'),
%             test = ~isempty(strfind(stemp,contain)); %check if contains for example 'SegmentNr_'
%             if test==1, result = 'y'; end;
%         end
% 
%         if result == 'y',
%             ylist{length(ylist)+1,1} = stemp;    
%         else
%             nlist{length(nlist)+1,1} = stemp;            
%         end;
%     end
%     if isempty(indexy)==false || strcmp(result,'y'),
%         accepted = 1;
%     else
%         accepted = 0;
%     end
% end




