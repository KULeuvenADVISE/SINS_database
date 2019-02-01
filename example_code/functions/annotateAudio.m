%% Annotation tool for time streams
%
% function labelvector = annotateAudio(data,fs,labels,labelvector,info)
% Input:
%	data - input data (single channel vector)
%	fs   - sampling frequency (scalar)
%	labels - label strings (cell)
%	labelvector - sample level label vector (vector: data length x labels), if [], then is initted as zeros
% 	info - add some information of the file to the title of the plot window
% Output
%	labelvector - sample level label vector (vector: data length x labels)
%
% Usage:
% 	At the top you have to select the classes you want to SET or ERASE at a certain point in time. 
% 	If the soundfile is playing it overwrites the annotation given those settings
%	Annotation by playing:
% 	Arrow left: slow down playing speed
%	Arrow right: speed up playing speed
%	Arrow up: start playing forward
%	Arrow down: start playing backward
%	Space: pause playing
% 	
%	A faster way to annotate (in case of e.g. events) can be done by annotating the data between two clicks.
%	You can change the current position of the playback of the waveform by clicking on it.
%	a: play the audio between the last two clicks
%	f: annotate values given the above settings
%	Note: if you changed setting you need to first unfocus by clicking on an area (topright)
%
% Authors: Gert Dekkers, Bert Van Den Broeck / KU Leuven

function labelvector = annotateAudio(data,fs,labels,labelvector,info)
    %% disable normal warning
    warning('off','dsp:system:toAudioDeviceDroppedSamples');

    %% globals
    global running
    global speed
    global handles
    global writeOn
    global writeOff
    global audioIndex
    global audioIndex_prev
    global writeOn_prev
    global writeOff_prev
    global fastAnno_toggle
    global fastAnnoAudio_toggle
    global proceed
    
    %% param
    % samples per frame
    samplePerFrame = 0.25*fs;
    % low res stepsize
    stepsize_samp = 0.001*fs;
    
    %% create GUI
    createGUI(length(data),labels,stepsize_samp,info);
    
    %% init
    % write on off
    [writeOn,writeOff] = deal(zeros(1,length(labels)));
    % playing parameters
    running = false;
    speed = 1;
    % audio player
    handles.audioPlayer = dsp.AudioPlayer('SampleRate',fs,'BufferSizeSource','Property',...
                        'BufferSize',samplePerFrame,'QueueDuration',0);
    % the audioplot
    set(handles.soundplot,'YData',data);
    % label vector
    if isempty(labelvector)
        labelvector = zeros(length(data),length(labels)); 
    end
    fastAnno_toggle = false;
    
    %% create callbacks
    set(handles.fig,'Interruptible','off','KeyPressFcn',@keyPress);
    set(handles.soundAx,'Interruptible','off','ButtonDownFcn',@newTime);
    set(handles.timelineAx,'Interruptible','off','ButtonDownFcn',@newTime);
    for i = 1:length(labels)
        set(handles.labelButtonUp(i),'Callback',@labelOn,'Interruptible','off');
        set(handles.labelButtonDown(i),'Callback',@labelOff,'Interruptible','off');
    end

    %% loop over all audio frames
    audioIndex = 1; audioIndex_prev = 1; [writeOn_prev,writeOff_prev] = deal(zeros(1,length(labels))); proceed = 1;
    update_timeline(labels,labelvector,stepsize_samp);
    while proceed
        if running == true
            % load the audiochannel in soundcard buffer
            samps = (audioIndex:audioIndex+samplePerFrame-1)+(stepsize_samp*2);
            samps(samps<1) = [];
            samps(samps>length(data)) = [];
            if ~isempty(samps), step(handles.audioPlayer,data(samps,1)); end
            % plot
            set(handles.timeplot,'XData',[audioIndex audioIndex]);
            set(handles.timeplotOnTimeLine,'XData',[audioIndex audioIndex]);
            
            % get value of speed so it does not change when during this loop
            cur_speed = speed;
            
            %% Update labels
            if (sum(writeOn)+sum(writeOff))>0 %only update if needed                
                labelvector(max(min([audioIndex_prev:audioIndex audioIndex:audioIndex_prev],length(labelvector)),1),writeOn==1 & writeOn_prev==1) = 1;
                labelvector(max(min([audioIndex_prev:audioIndex audioIndex:audioIndex_prev],length(labelvector)),1),writeOff==1 & writeOff_prev==1) = 0;
                update_timeline(labels,labelvector,stepsize_samp);
            end
            
            % Keep last states
            audioIndex_prev = audioIndex;
            writeOn_prev = writeOn;
            writeOff_prev = writeOff;

            % ensure time for callbacks
            drawnow;
            
            %% increase indexes
            audioIndex = min(max(audioIndex + samplePerFrame*cur_speed,1),length(labelvector));
        elseif fastAnno_toggle    
            % Update labels
            if (sum(writeOn)+sum(writeOff))>0 %only update if needed                
                labelvector(max(min([audioIndex_prev:audioIndex audioIndex:audioIndex_prev],length(labelvector)),1),writeOn==1) = 1;
                labelvector(max(min([audioIndex_prev:audioIndex audioIndex:audioIndex_prev],length(labelvector)),1),writeOff==1) = 0;
                update_timeline(labels,labelvector,stepsize_samp);
            end
            % ensure time for callbacks
            drawnow;
            % reset
            fastAnno_toggle = false;
        elseif fastAnnoAudio_toggle
            % play back audio
            soundsc(data(audioIndex_prev:audioIndex),fs);
            % reset
            fastAnnoAudio_toggle = false;
        else
            figure(handles.fig);
            pause(0.5);
        end
     end
        
    %% close GUI
    close(handles.fig);
end

function update_timeline(labels,labelvector,stepsize_samp)
    global handles
    for i=1:length(labels) %update plot
        set(handles.labelplot(i),'YData',labelvector(1:stepsize_samp:end,i)*0.8+(length(labels)-i));
    end
end

function labelOn(a,b)
    global writeOn    
    global handles;
    for i = 1:length(handles.labelButtonUp)
        if a==handles.labelButtonUp(i)
            if get(handles.labelButtonUp(i),'Value')==1
                writeOn(i) = 1;
                set(handles.labelButtonDown(i),'Enable','Off');
            else
                writeOn(i) = 0;
                set(handles.labelButtonDown(i),'Enable','On');
            end
        end
    end
end

function labelOff(a,b)
    global writeOff    
    global handles;
    for i = 1:length(handles.labelButtonDown)
        if a==handles.labelButtonDown(i)
            if get(handles.labelButtonDown(i),'Value')==1
                writeOff(i) = 1;
                set(handles.labelButtonUp(i),'Enable','Off');
            else
                writeOff(i) = 0;
                set(handles.labelButtonUp(i),'Enable','On');
            end
        end
    end
end


function newTime(a,b)
    global audioIndex
    global audioIndex_prev
    global handles
    t = get(a,'CurrentPoint'); t = round(t(1,1));
    audioIndex_prev = audioIndex;
    audioIndex = t;
    % update timeline
    set(handles.timeplot,'XData',[audioIndex audioIndex]);
    set(handles.timeplotOnTimeLine,'XData',[audioIndex audioIndex]);
end

function keyPress(~,b)    
    if double(b.Character)==28      % arrow left  -> slowdown
        audioSlowdown;
    elseif double(b.Character)==29  % arrow right -> speedup
        audioSpeedup;
    elseif double(b.Character)==30  % arrow up    -> start playing forward
        audioPlay;
    elseif double(b.Character)==31  % arrow down  -> start playing backward
        audioPlayBackward;        
    elseif double(b.Character)==32  % space       -> pause playing
        audioPause;
    elseif double(b.Character)==13  % enter       -> end session
        audioNext;
    elseif double(b.Character)==102  % f -> fast anno mode
        fastAnno;
    elseif double(b.Character)==97  % a -> fast anno mode
        fastAnnoAudio;
    end
end

function fastAnnoAudio(~,~) 
    global fastAnnoAudio_toggle
    fastAnnoAudio_toggle = true;
end

function fastAnno(~,~) 
    global fastAnno_toggle
    fastAnno_toggle = true;
end

function audioNext(~,~) 
    global proceed
    proceed = 0;
end

function audioPause(~,~)
    global running
    running = false;
end

function audioPlay(~,~)
    global running
    global speed
    running = true;
    speed = 1;
end

function audioPlayBackward(~,~)
    global running
    global speed
    running = true;
    speed = -1;
end


function audioSpeedup(~,~)
    % global variables
    global speed
    speed = speed*2;
end

function audioSlowdown(~,~)
    % global variables
    global speed
    if abs(speed)>1
        speed = speed/2;
    end
end

function createGUI(plotSize,labels,stepsize_samp,info)
    %% globals
    global handles

    % figure position absolute
    fig = [1 31 1920 1028];
        % timeline panel
        timelinePanel = [0 0 1 0.4];
            % timeline plot
            timeLineAx = [0 0 1 1];
        % sound panel
        soundPanel = [0 0.4 1 0.3];
            % sound ax
            soundAx = [0 0 1 1];
        % label panel
        labelPanel = [0 0.7 0.9 0.3];
            % labels buttons automatically defined
            
    %% colors
    color_cell = colorrange;

    %% create all objects
    % figure object
    if ~isempty(info), suffix = []; else, suffix = [' - Info: ' info]; end
    handles.fig = figure('position',fig,'menubar', 'none','NumberTitle','off','Name',['Annotate window' suffix]);
        % timeline panel
        handles.timelinePanel = uipanel('Parent',handles.fig,'Title','Timeline','Position',timelinePanel);
            % timeline plot
            handles.timelineAx = subplot('position',timeLineAx,'Parent',handles.timelinePanel); xlim([0 plotSize/stepsize_samp+1]);
            for i=1:length(labels)
            handles.labelplot(i) = plot(1:stepsize_samp:plotSize,(length(labels)-i)*ones(floor(plotSize/stepsize_samp+1),1),'LineWidth',3,'Color',color_cell{i}/255); hold('on');
            end
            handles.timeplotOnTimeLine = plot([1 1], [-1 length(labels)+0.2],'r');
            ylim([-0.2 length(labels)+0.2]);
            lh = legend(labels); %lh.PlotChildren = lh.PlotChildren(end:-1:1);
        % sound panel
        handles.soundPanel = uipanel('Parent',handles.fig,'Title','Sound','Position',soundPanel);
            % sound ax
            handles.soundAx = subplot('position',soundAx,'Parent',handles.soundPanel); xlim([0 plotSize]);
            handles.soundplot = plot(zeros(1,plotSize)); hold('on');
            handles.timeplot = plot([1 1], [-0.2 1.2],'r');
            ylim([0 1]);
        % labels panel
        handles.labelPanel = uipanel('Parent',handles.fig,'Title','Labels','Position',labelPanel);
            % labels buttons
            makeLabelButtons(labels);
        
    %% draw
    drawnow;
end

function makeLabelButtons(labels)
    %% globals
    global handles
    
    %% delete previous labels buttons and strings (if exist)
    allChildren = get(handles.labelPanel,'Children');
    for i = 1:length(allChildren)
        delete(allChildren(i));
    end
    handles.labelnames = [];
    handles.labelButtonUpDown = [];
    
    %% colors
    color_cell = colorrange;
    
    %% make new ones
    ButtonSize = min(1/(ceil(length(labels)/2)),1);
    ButtonWidth = 0.5/3;
    for i = 1:length(labels)
        max_height = ceil(length(labels)/2);
        if i>max_height, sec_row = 1; else, sec_row = 0; end;
        x_offset = sec_row*ButtonWidth*3;
        y_offset = sec_row*max_height;
        handles.labelnames(i) = uicontrol('Style', 'text', 'String', labels{i},'Units',...
            'normalized','Position',[0+x_offset (max_height-(i-y_offset))*ButtonSize ButtonWidth ButtonSize],'Parent',handles.labelPanel,'BackgroundColor',[1 1 1],'ForegroundColor',color_cell{i}/255,'FontSize',20);
        handles.labelButtonUp(i) = uicontrol('Style', 'togglebutton','Units','normalized',...
            'Position',[ButtonWidth+x_offset  (max_height-(i-y_offset))*ButtonSize ButtonWidth ButtonSize],'Parent',handles.labelPanel,'String','up','FontSize',20);
        handles.labelButtonDown(i) = uicontrol('Style', 'togglebutton','Units','normalized',...
            'Position',[ButtonWidth*2+x_offset (max_height-(i-y_offset))*ButtonSize ButtonWidth ButtonSize],'Parent',handles.labelPanel,'String','down','FontSize',20);
    end
end

function color_cell = colorrange()
col_red = [255 0 0];
col_darkred = [100 0 0];
col_darkgreen = [0 100 0];
col_green2 = [0 238 0];
col_orange = [255 165 0];
col_darkorange = [100 50 0];
col_mediumblue = [0 0 205];
col_deepskyblue = [0 191 255];
col_deeppink = [255 20 147];
col_purple = [160 32 240];
col_darkblue = [0 0 100];
col_lichtblue = [0 0 255];
col_darkpink = [150 5 100];
col_lichtskyblue=[0 50 150];
col_gray1=[50 50 50];
col_gray2=[100 100 100];
col_gray3=[150 150 150];
col_black=[0 0 0];
color_cell = { col_darkred, col_darkgreen,  col_orange,col_mediumblue, col_deepskyblue, ...
    col_deeppink,  col_darkblue, col_green2, col_lichtblue, col_darkpink, col_lichtskyblue, col_gray1, col_purple,col_red, col_gray2, col_gray3,col_black};
end



