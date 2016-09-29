%-----------------------------------------------------------------------------%
% In der vorliegenden Datei werden Konstanten und Felder definiert,           %
% die fuer Zugriffe auf emg-Dateien benoetigt werden.                         %
%-----------------------------------------------------------------------------%

%-----------------------------------------------------------------------------%
%               D  A  T  E  I  H  E  A  D  E  R                               %                            
%-----------------------------------------------------------------------------%

%%%
% Headerversion: 0 = Version vor 2009, 
%                1 = Version seit 2009

POSITION_HEADER_VERSION_INFO = 96;
SIZE_HEADER_VERSION_INFO     = 'int32';

%%%
% Anzahl der gespeicherten Kanaele

POSITION_EMG_NUMCHANNEL      = 42;
SIZE_EMG_NUMCHANNEL          = 'int16';

%%%
% Samplingrate

POSITION_EMG_SAMPLING        = 76;
SIZE_EMG_SAMPLING            = 'float32';

%%%
% Anzahl gespeichertete Samples

POSITION_EMG_NUMSAMPLES      = 80;
SIZE_EMG_NUMSAMPLES          = 'uint32';

%%%
% Position ab der Informationen zu jedem
% einzelnen Kanal gespeichert sind

POSITION_EMG_CHANNELINFO     = 1108; % Feld mit Struktur [32/96 * 580 Byte] 

% Position eines Flag innerhalb eines Infoblocks,
% das markiert, ob der jeweilige Kanal gespeichert
% ist (Bit 1 gesetzt) oder nicht.

POSITION_CHANNELFLAG         = 2;
SIZE_CHANNELFLAG             = 'int16';

% Position des VoltPerBit-Eintrags innerhalb der 
% Kanal-Struktur

POSITION_VOLTPERBIT          = 152; 
SIZE_VOLTPERBIT              = 'float32';

% Groesse der Kanalstruktur

SIZE_CHANNEL_STRUCT          = 580;

%%%
% Indizierung der nachfolgenden Felder erfolgt 
% ueber Wert bei HEADER_VERSION_INFO
%
% Anzahl an moeglichen Kanaelen, abhaengig von 
% der Headerversion

NUM_EMG_CHANNELS    = [32, 96];

% Groesse des Dateiheaders abhaengig von der 
% Headerversion

SIZE_EMG_FILEHEADER = [19668, 56788];

%-----------------------------------------------------------------------------%
%               D  A  T  E  N                                                 %                            
%-----------------------------------------------------------------------------%

SIZE_EMG_DATASAMPLE      = 'float32';
BYTES_EMG_DATASAMPLE     = 4;

SIZE_EMG_ADSAMPLE        = 'int16';
BYTES_EMG_ADSAMPLE       = 2;

SIZE_EMG_TRIGGERSAMPLE   = 'uint32';
BYTES_EMG_TRIGGERSAMPLE  = 4;

%SIZE_EMG_TIMESTAMPSAMPLE  = ;
%BYTES_EMG_TIMESTAMPSAMPLE = 8;

