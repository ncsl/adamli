function make_dbs_readme_struct(homeDir, subject)

% subject='DBS015'
% homeDir='/Users/andrewyang/Desktop/orig_data';


outputDir=fullfile(homeDir,subject,'docs');

    % read in readme file
    if exist(fullfile(homeDir,subject,'docs','README.txt'))
        DBS_params.name=subject;
        read_me=textread(fullfile(homeDir,subject,'docs','README.txt'),'%s');
    else
        disp([subject ' has no README']);
    end
    
    % AC & PC & mid-commissural point
    coor=find(strcmpi(read_me,'ac'));
    if ~isempty(coor)
        if coor
            DBS_params.ac.x=str2num(read_me{coor+2});
            DBS_params.ac.y=str2num(read_me{coor+4});
            DBS_params.ac.z=str2num(read_me{coor+6});
        end
        
        coor=find(strcmpi(read_me,'pc'));
        if coor
            DBS_params.pc.x=str2num(read_me{coor+2});
            DBS_params.pc.y=str2num(read_me{coor+4});
            DBS_params.pc.z=str2num(read_me{coor+6});
        end
    end
    
    % target (STN or GPi)
    coor1=find(strcmpi(read_me,'stn')); coor2=find(strcmpi(read_me,'gpi')); coor3=find(strcmpi(read_me,'vim'));
    if ~isempty(coor1)
        coor=coor1;
        DBS_params.targets(1).name=cell2mat([read_me(coor(1)-1) ' STN']);
        DBS_params.targets(2).name=cell2mat([read_me(coor(2)-1) ' STN']);
    elseif ~isempty(coor2)
        coor=coor2;
        DBS_params.targets(1).name=cell2mat([read_me(coor(1)-1) ' GPi']);
        DBS_params.targets(2).name=cell2mat([read_me(coor(2)-1) ' GPi']);    
    elseif ~isempty(coor3)
        coor=coor3;
        DBS_params.targets(1).name=cell2mat([read_me(coor(1)-1) ' ViM']);
        DBS_params.targets(2).name=cell2mat([read_me(coor(2)-1) ' ViM']);
    end
    DBS_params.targets(1).x=str2num(read_me{coor(1)+2});
    DBS_params.targets(1).y=str2num(read_me{coor(1)+4});
    DBS_params.targets(1).z=str2num(read_me{coor(1)+6});
    DBS_params.targets(1).decl=str2num(read_me{coor(1)+8})*pi/180;
    DBS_params.targets(1).azm=str2num(read_me{coor(1)+10})*pi/180;
    
    DBS_params.targets(2).x=str2num(read_me{coor(2)+2});
    DBS_params.targets(2).y=str2num(read_me{coor(2)+4});
    DBS_params.targets(2).z=str2num(read_me{coor(2)+6});
    DBS_params.targets(2).decl=str2num(read_me{coor(2)+8})*pi/180;
    DBS_params.targets(2).azm=str2num(read_me{coor(2)+10})*pi/180;
    
    % all tracks (no & name)
    coor=find(strcmpi(read_me,'impedance'));
    counter1=1; counter2=1; track_no=[]; track_name=[];
    track_no(counter1)=str2num(read_me{coor+counter2});
    while 1
        if strcmp(read_me(coor+counter2+1),'none')
            track_no(end)=[]; counter1=counter1-1;
            counter2=counter2+2;
        elseif ~isempty(str2num(read_me{coor+counter2+1}))
            track_no(end)=[]; counter1=counter1-1;
            counter2=counter2+1;
        else
            track_name{counter1}={cell2mat([read_me(coor+counter2+1) ' ' read_me(coor+counter2+2)])};
            counter2=counter2+3;
        end
        counter1=counter1+1;
        
        if str2num(read_me{coor+counter2})
            track_no(counter1)=str2num(read_me{coor+counter2});
        else
            break
        end
    end
    DBS_params.tracks.no=track_no;
    DBS_params.tracks.name=track_name;
    
    % tracks w/ recordings in STN (no, top & bottom of STN recordings in units mm)
    coor=find(strcmpi(read_me,'bottom'));
    counter1=1; counter2=1; track_no=[]; track_top=[]; track_bottom=[];
    track_no(counter1)=str2num(read_me{coor+counter2});
    while 1
        if isempty(str2num(read_me{coor+counter2+1})) || isempty(str2num(read_me{coor+counter2+2}))
            track_no(end)=[];
            break
        elseif isempty(str2num(read_me{coor+counter2+3}))
            if (str2num(read_me{coor+counter2+1})+1)~=str2num(read_me{coor+counter2+2})
                track_top(counter1)=str2num(read_me{coor+counter2+1});
                track_bottom(counter1)=str2num(read_me{coor+counter2+2});
            else
                track_no(end)=[];
            end
            break
        end
        
        if (track_no(counter1)+1)~=str2num(read_me{coor+counter2+1})
            track_top(counter1)=str2num(read_me{coor+counter2+1});
            track_bottom(counter1)=str2num(read_me{coor+counter2+2});
            counter2=counter2+3;
        elseif (track_no(counter1)+1)==str2num(read_me{coor+counter2+1})
            if (track_no(counter1)+1)==str2num(read_me{coor+counter2+3})
                track_top(counter1)=str2num(read_me{coor+counter2+1});
                track_bottom(counter1)=str2num(read_me{coor+counter2+2});
                counter2=counter2+3;
            else
                track_no(end)=[]; counter1=counter1-1;
                counter2=counter2+1;
            end
        end
        counter1=counter1+1;
        
        if str2num(read_me{coor+counter2})
            track_no(counter1)=str2num(read_me{coor+counter2});
        else
            break
        end
    end
    DBS_params.tracks.no_within_target=track_no;
    DBS_params.tracks.top=track_top;
    DBS_params.tracks.bottom=track_bottom;

save(fullfile(outputDir,'dbs_readme.mat'),'DBS_params')