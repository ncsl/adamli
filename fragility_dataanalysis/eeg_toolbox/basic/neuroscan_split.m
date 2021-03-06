function basename = neuroscan_split(neuroscanfile,subject,basedir)
% NEUROSCAN_SPLIT - Process a continuous file exported from
% neuroscan. This script has been adapted from EEGLAB's loadcnt.m function
%
% FUNCTION:
%    neuroscan_split(neuroscanfile,subject,basedir)
%
% INPUT ARGS:
%  neuroscanfile = 'xxxxx'
%  subject = 'SF001'
%  basedir = '/data/eeg/SF001/eeg.reref' - directory to put split
%  out channel files
%
% OUTPUT ARGS
%  basename - the basename determined from the subject and file
% STILL NEED TO FIGURE OUT WHETHER GAIN HAS BEEN APPLIED OR HAS TO
% BE APPLIED TO THE DATA--IN OTHER WORDS: ARE THE UNITS CORRECT?
% IT MAY BE THE CASE THAT THE GAIN FACTOR WILL HAVE TO BE ADAPTED
% FOR PARTICULAR USES OF THIS SCRIPT

% check input vars
if ~exist('subject','var')
  disp('You must supply a subject ID.');
  return
end

% months
month = {'Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'};

if ~exist('basedir','var')
  basedir = '.';
end

outputformat = 'short';
ampgain  =0.168; %set to 1 for now (no gain applied)
r = [];
r.dataformat = 'int16';

sizeEvent1 = 8  ; %%% 8  bytes for Event1  
sizeEvent2 = 19 ; %%% 19 bytes for Event2


%check whether basedir exists, if not, create it
if ~exist(basedir,'dir')
  mkdir(basedir)
end

% read the header
fid = fopen(neuroscanfile,'r', 'l');

h.rev               = fread(fid,12,'char');
h.nextfile          = fread(fid,1,'long');
h.prevfile          = fread(fid,1,'long');
h.type              = fread(fid,1,'char');
h.id                = fread(fid,20,'char');
h.oper              = fread(fid,20,'char');
h.doctor            = fread(fid,20,'char');
h.referral          = fread(fid,20,'char');
h.hospital          = fread(fid,20,'char');
h.patient           = fread(fid,20,'char');
h.age               = fread(fid,1,'short');
h.sex               = fread(fid,1,'char');
h.hand              = fread(fid,1,'char');
h.med               = fread(fid,20, 'char');
h.category          = fread(fid,20, 'char');
h.state             = fread(fid,20, 'char');
h.label             = fread(fid,20, 'char');
h.date              = fread(fid,10, 'char');
h.time              = fread(fid,12, 'char');
h.mean_age          = fread(fid,1,'float');
h.stdev             = fread(fid,1,'float');
h.n                 = fread(fid,1,'short');
h.compfile          = fread(fid,38,'char');
h.spectwincomp      = fread(fid,1,'float');
h.meanaccuracy      = fread(fid,1,'float');
h.meanlatency       = fread(fid,1,'float');
h.sortfile          = fread(fid,46,'char');
h.numevents         = fread(fid,1,'int');
h.compoper          = fread(fid,1,'char');
h.avgmode           = fread(fid,1,'char');
h.review            = fread(fid,1,'char');
h.nsweeps           = fread(fid,1,'ushort');
h.compsweeps        = fread(fid,1,'ushort');
h.acceptcnt         = fread(fid,1,'ushort');
h.rejectcnt         = fread(fid,1,'ushort');
h.pnts              = fread(fid,1,'ushort');
h.nchannels         = fread(fid,1,'ushort');
h.avgupdate         = fread(fid,1,'ushort');
h.domain            = fread(fid,1,'char');
h.variance          = fread(fid,1,'char');
h.rate              = fread(fid,1,'ushort');
h.scale             = fread(fid,1,'double');
h.veogcorrect       = fread(fid,1,'char');
h.heogcorrect       = fread(fid,1,'char');
h.aux1correct       = fread(fid,1,'char');
h.aux2correct       = fread(fid,1,'char');
h.veogtrig          = fread(fid,1,'float');
h.heogtrig          = fread(fid,1,'float');
h.aux1trig          = fread(fid,1,'float');
h.aux2trig          = fread(fid,1,'float');
h.heogchnl          = fread(fid,1,'short');
h.veogchnl          = fread(fid,1,'short');
h.aux1chnl          = fread(fid,1,'short');
h.aux2chnl          = fread(fid,1,'short');
h.veogdir           = fread(fid,1,'char');
h.heogdir           = fread(fid,1,'char');
h.aux1dir           = fread(fid,1,'char');
h.aux2dir           = fread(fid,1,'char');
h.veog_n            = fread(fid,1,'short');
h.heog_n            = fread(fid,1,'short');
h.aux1_n            = fread(fid,1,'short');
h.aux2_n            = fread(fid,1,'short');
h.veogmaxcnt        = fread(fid,1,'short');
h.heogmaxcnt        = fread(fid,1,'short');
h.aux1maxcnt        = fread(fid,1,'short');
h.aux2maxcnt        = fread(fid,1,'short');
h.veogmethod        = fread(fid,1,'char');
h.heogmethod        = fread(fid,1,'char');
h.aux1method        = fread(fid,1,'char');
h.aux2method        = fread(fid,1,'char');
h.ampsensitivity    = fread(fid,1,'float');
h.lowpass           = fread(fid,1,'char');
h.highpass          = fread(fid,1,'char');
h.notch             = fread(fid,1,'char');
h.autoclipadd       = fread(fid,1,'char');
h.baseline          = fread(fid,1,'char');
h.offstart          = fread(fid,1,'float');
h.offstop           = fread(fid,1,'float');
h.reject            = fread(fid,1,'char');
h.rejstart          = fread(fid,1,'float');
h.rejstop           = fread(fid,1,'float');
h.rejmin            = fread(fid,1,'float');
h.rejmax            = fread(fid,1,'float');
h.trigtype          = fread(fid,1,'char');
h.trigval           = fread(fid,1,'float');
h.trigchnl          = fread(fid,1,'char');
h.trigmask          = fread(fid,1,'short');
h.trigisi           = fread(fid,1,'float');
h.trigmin           = fread(fid,1,'float');
h.trigmax           = fread(fid,1,'float');
h.trigdir           = fread(fid,1,'char');
h.autoscale         = fread(fid,1,'char');
h.n2                = fread(fid,1,'short');
h.dir               = fread(fid,1,'char');
h.dispmin           = fread(fid,1,'float');
h.dispmax           = fread(fid,1,'float');
h.xmin              = fread(fid,1,'float');
h.xmax              = fread(fid,1,'float');
h.automin           = fread(fid,1,'float');
h.automax           = fread(fid,1,'float');
h.zmin              = fread(fid,1,'float');
h.zmax              = fread(fid,1,'float');
h.lowcut            = fread(fid,1,'float');
h.highcut           = fread(fid,1,'float');
h.common            = fread(fid,1,'char');
h.savemode          = fread(fid,1,'char');
h.manmode           = fread(fid,1,'char');
h.ref               = fread(fid,10,'char');
h.rectify           = fread(fid,1,'char');
h.displayxmin       = fread(fid,1,'float');
h.displayxmax       = fread(fid,1,'float');
h.phase             = fread(fid,1,'char');
h.screen            = fread(fid,16,'char');
h.calmode           = fread(fid,1,'short');
h.calmethod         = fread(fid,1,'short');
h.calupdate         = fread(fid,1,'short');
h.calbaseline       = fread(fid,1,'short');
h.calsweeps         = fread(fid,1,'short');
h.calattenuator     = fread(fid,1,'float');
h.calpulsevolt      = fread(fid,1,'float');
h.calpulsestart     = fread(fid,1,'float');
h.calpulsestop      = fread(fid,1,'float');
h.calfreq           = fread(fid,1,'float');
h.taskfile          = fread(fid,34,'char');
h.seqfile           = fread(fid,34,'char');
h.spectmethod       = fread(fid,1,'char');
h.spectscaling      = fread(fid,1,'char');
h.spectwindow       = fread(fid,1,'char');
h.spectwinlength    = fread(fid,1,'float');
h.spectorder        = fread(fid,1,'char');
h.notchfilter       = fread(fid,1,'char');
h.headgain          = fread(fid,1,'short');
h.additionalfiles   = fread(fid,1,'int');
h.unused            = fread(fid,5,'char');
h.fspstopmethod     = fread(fid,1,'short');
h.fspstopmode       = fread(fid,1,'short');
h.fspfvalue         = fread(fid,1,'float');
h.fsppoint          = fread(fid,1,'short');
h.fspblocksize      = fread(fid,1,'short');
h.fspp1             = fread(fid,1,'ushort');
h.fspp2             = fread(fid,1,'ushort');
h.fspalpha          = fread(fid,1,'float');
h.fspnoise          = fread(fid,1,'float');
h.fspv1             = fread(fid,1,'short');
h.montage           = fread(fid,40,'char');
h.eventfile         = fread(fid,40,'char');
h.fratio            = fread(fid,1,'float');
h.minor_rev         = fread(fid,1,'char');
h.eegupdate         = fread(fid,1,'short');
h.compressed        = fread(fid,1,'char');
h.xscale            = fread(fid,1,'float');
h.yscale            = fread(fid,1,'float');
h.xsize             = fread(fid,1,'float');
h.ysize             = fread(fid,1,'float');
h.acmode            = fread(fid,1,'char');
h.commonchnl        = fread(fid,1,'uchar');
h.xtics             = fread(fid,1,'char');
h.xrange            = fread(fid,1,'char');
h.ytics             = fread(fid,1,'char');
h.yrange            = fread(fid,1,'char');
h.xscalevalue       = fread(fid,1,'float');
h.xscaleinterval    = fread(fid,1,'float');
h.yscalevalue       = fread(fid,1,'float');
h.yscaleinterval    = fread(fid,1,'float');
h.scaletoolx1       = fread(fid,1,'float');
h.scaletooly1       = fread(fid,1,'float');
h.scaletoolx2       = fread(fid,1,'float');
h.scaletooly2       = fread(fid,1,'float');
h.port              = fread(fid,1,'short');
h.numsamples        = fread(fid,1,'ulong');
h.filterflag        = fread(fid,1,'char');
h.lowcutoff         = fread(fid,1,'float');
h.lowpoles          = fread(fid,1,'short');
h.highcutoff        = fread(fid,1,'float');
h.highpoles         = fread(fid,1,'short');
h.filtertype        = fread(fid,1,'char');
h.filterdomain      = fread(fid,1,'char');
h.snrflag           = fread(fid,1,'char');
h.coherenceflag     = fread(fid,1,'char');
h.continuoustype    = fread(fid,1,'char');
h.eventtablepos     = fread(fid,1,'long');
h.continuousseconds = fread(fid,1,'float');
h.channeloffset     = fread(fid,1,'long');
h.autocorrectflag   = fread(fid,1,'char');
h.dcthreshold       = fread(fid,1,'uchar');

% construct basename
day = char(h.date(1:2))';
themonth = char(h.date(4:5))';
themonth = str2num(themonth);
year = char(h.date(7:8))';
h.time = [char(h.time(1:2))' char(h.time(4:5))'];
basename = [subject '_' day month{themonth} year '_' h.time];

% Give them some file info
fprintf('EEG File Information:\n')
fprintf('---------------------\n')
fprintf('Sample Rate = %d\n', h.rate);
fprintf('Start of recording = %d/%d/%d:%s\n',str2num(day),themonth,str2num(year),h.time);
fprintf('Number of Channels = %d\n', h.nchannels);
fprintf('Number of Events = %d\n', h.numevents);
fprintf('Base Name = %s\n', basename);
fprintf('\n');

for n = 1:h.nchannels
    e(n).lab            = deblank(char(fread(fid,10,'char')'));
    e(n).reference      = fread(fid,1,'char');
    e(n).skip           = fread(fid,1,'char');
    e(n).reject         = fread(fid,1,'char');
    e(n).display        = fread(fid,1,'char');
    e(n).bad            = fread(fid,1,'char');
    e(n).n              = fread(fid,1,'ushort');
    e(n).avg_reference  = fread(fid,1,'char');
    e(n).clipadd        = fread(fid,1,'char');
    e(n).x_coord        = fread(fid,1,'float');
    e(n).y_coord        = fread(fid,1,'float');
    e(n).veog_wt        = fread(fid,1,'float');
    e(n).veog_std       = fread(fid,1,'float');
    e(n).snr            = fread(fid,1,'float');
    e(n).heog_wt        = fread(fid,1,'float');
    e(n).heog_std       = fread(fid,1,'float');
    e(n).baseline       = fread(fid,1,'short');
    e(n).filtered       = fread(fid,1,'char');
    e(n).fsp            = fread(fid,1,'char');
    e(n).aux1_wt        = fread(fid,1,'float');
    e(n).aux1_std       = fread(fid,1,'float');
    e(n).senstivity     = fread(fid,1,'float');
    e(n).gain           = fread(fid,1,'char');
    e(n).hipass         = fread(fid,1,'char');
    e(n).lopass         = fread(fid,1,'char');
    e(n).page           = fread(fid,1,'uchar');
    e(n).size           = fread(fid,1,'uchar');
    e(n).impedance      = fread(fid,1,'uchar');
    e(n).physicalchnl   = fread(fid,1,'uchar');
    e(n).rectify        = fread(fid,1,'char');
    e(n).calib          = fread(fid,1,'float');
end


% finding if 32-bits of 16-bits file
% ----------------------------------
begdata = ftell(fid);
enddata = h.eventtablepos;   % after data
if strcmpi(r.dataformat, 'int16')
     nums    = (enddata-begdata)/h.nchannels/2;
else nums    = (enddata-begdata)/h.nchannels/4;
end;

% load the rest of the file
r.sample1 = 0;
startpos = 0;
r.ldnsamples = nums;

fseek(fid, startpos, 0);
dat = zeros(r.ldnsamples,1);

if h.channeloffset <= 1
  % read the data in steps
  stepsize = 100000;
  % make sure the stepsize is a multiple of the number of channels
  stepsize = stepsize*h.nchannels;
  nums = r.ldnsamples*h.nchannels;
  numSteps = fix((nums)/stepsize);
  totalread = 0;
  for s = 1:numSteps
    while totalread < nums
      sampsleft = nums - totalread;
      if sampsleft < stepsize
	toread = sampsleft;
      else
	toread = stepsize;
      end
      fprintf('%d ',totalread);
      % read the data
      dat = int16(fread(fid,[h.nchannels fix(toread/h.nchannels)],r.dataformat));
      totalread = totalread+toread;
      % now write the data to file for every channel
      for c = 1:h.nchannels
	fidw = fopen(fullfile(basedir,[basename '.' num2str(c,'%03d')]),'ab','l');
	fwrite(fidw,dat(c,:),outputformat);
	fclose(fidw);  	
      end	
    end
  end
  %dat=fread(fid, [h.nchannels r.ldnsamples], r.dataformat);
else
  % THIS PART OF THE CODE DOES NOT WORK!!
  h.channeloffset = h.channeloffset/2;
  % reading data in blocks
  dat = zeros( h.nchannels, r.ldnsamples);
  dat(:, 1:h.channeloffset) = fread(fid, [h.channeloffset h.nchannels], r.dataformat)';

  counter = 1;	
  while counter*h.channeloffset < r.ldnsamples
    dat(:, counter*h.channeloffset+1:counter*h.channeloffset+h.channeloffset) = fread(fid, [h.channeloffset h.nchannels], r.dataformat)';
    counter = counter + 1;
  end;
end;	
            
fseek(fid, h.eventtablepos, 'bof');      
%disp('Reading Event Table...')
eT.teeg   = fread(fid,1,'uchar');
eT.size   = fread(fid,1,'ulong');
eT.offset = fread(fid,1,'ulong');
      
if eT.teeg==2
  nevents=eT.size/sizeEvent2;
  if nevents > 0
    ev2(nevents).stimtype  = [];
    for i=1:nevents
      ev2(i).stimtype      = fread(fid,1,'ushort');
      ev2(i).keyboard      = fread(fid,1,'char');
      ev2(i).keypad_accept = fread(fid,1,'char');
      ev2(i).offset        = fread(fid,1,'long');
      ev2(i).type          = fread(fid,1,'short'); 
      ev2(i).code          = fread(fid,1,'short');
      ev2(i).latency       = fread(fid,1,'float');
      ev2(i).epochevent    = fread(fid,1,'char');
      ev2(i).accept        = fread(fid,1,'char');
      ev2(i).accuracy      = fread(fid,1,'char');
    end     
  else
    ev2 = [];
  end;
elseif eT.teeg==1
  nevents=eT.size/sizeEvent1;
  if nevents > 0
    ev2(nevents).stimtype  = [];
    for i=1:nevents
      ev2(i).stimtype      = fread(fid,1,'ushort');
      ev2(i).keyboard      = fread(fid,1,'char');
      ev2(i).keypad_accept = fread(fid,1,'char');
      ev2(i).offset        = fread(fid,1,'long');
    end;
  else
    ev2 = [];
  end;
else
  %disp('Skipping event table (tag != 1,2 ; theoretically impossible)');
  ev2 = [];
end     

fseek(fid, -1, 'eof');
t = fread(fid,'char');

%%%% to change offest in bytes to points 
if ~isempty(ev2)
    ev2p=ev2; 
    ioff=900+(h.nchannels*75); %% initial offset : header + electordes desc 
    if strcmpi(r.dataformat, 'int16')
        for i=1:nevents 
            ev2p(i).offset=(ev2p(i).offset-ioff)/(2*h.nchannels) - r.sample1; %% 2 short int end 
        end     
    else % 32 bits
        for i=1:nevents 
            ev2p(i).offset=(ev2p(i).offset-ioff)/(4*h.nchannels) - r.sample1; %% 4 short int end 
        end     
    end;        
    f.event = ev2p;
end;

frewind(fid);
fclose(fid);

fprintf('Processing %d channels and events:\n',size(dat,1));



% loop over channels and write to files
% open all the chan files
% for c = 1:h.nchannels
%   fprintf('%d ',c);
%   fid = fopen(fullfile(basedir,[basename '.' num2str(c,'%03d')]),'wb','l');
%   fwrite(fid,dat(c,:),outputformat);
%   fclose(fid);
% end

% fprintf('\n');
 


% write out params.txt file
paramfile = fullfile(basedir,'params.txt');
fid = fopen(paramfile,'w');
fprintf(fid,'samplerate %d\ndataformat ''%s''\ngain %g\n',h.rate,outputformat,ampgain);
fclose(fid);
           

% write out new params.txt file
paramfile = fullfile(basedir,[basename '.params.txt']);
fid = fopen(paramfile,'w');
fprintf(fid,'samplerate %d\ndataformat ''%s''\ngain %g\n',h.rate,outputformat,ampgain);
fclose(fid);
