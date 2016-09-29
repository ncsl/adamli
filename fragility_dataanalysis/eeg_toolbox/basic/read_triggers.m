function trg = read_triggers(filename, amp_idx)
% TRG = READ_TRIGGERS(FILENAME) reads the Inomed Trigger file 
% FILENAME (in the format available since August 2009)
% and returns the triggers available in that file in TRG.
% The first column of TRG contains the timestamp of the
% trigger (in samples), the second column its identity
% (at present, the identity value is always '4').
% The third column is the number of the amplifier that
% received that trigger.
% 
% TRG = READ_TRIGGERS(FILENAME, AMP_IDX) returns only
% the timestampfs of the triggers received by amplifier
% AMP_IDX.


% A. Brandt

COMMENT_OFS = 44;

MAX_CHANNEL_NO = 96;
FILE_HDR_SZ = 1108;
CHANNEL_HDR_SZ = 580;
HDR_SIZE = FILE_HDR_SZ + MAX_CHANNEL_NO * CHANNEL_HDR_SZ;


fid = fopen(filename, 'r');
if (fid < 0)
   fid = fopen([filename '.trg'], 'r');
   if (fid < 0)
      trg =  [];
      return;
   end
end

fseek(fid, COMMENT_OFS, 'bof');
comment = fread(fid, [1, 30], '*char');
if ~strncmpi(comment, 'Timestamp', length('Timestamp'))
    error('currently, only timestamp trigger files can be read with this script.');
end
fseek(fid, HDR_SIZE, 'bof');
trg = fread(fid, [4 inf], 'uint16');
fclose(fid);
% trg(1,:) and trg(2,:) together contain a 32bit value, which is
% recreated from 2 16bit values in the following line
if ~isempty(trg)
  trg(1, :) = trg(1,:)+2^16*trg(2,:);
  trg = trg([1, 3, 4], :)';
end

% return only timestamps for one amplifier, if amp_idx is given as an argument
if (nargin > 1)
  trg = trg(trg(:, 3) == amp_idx, 1);
end
