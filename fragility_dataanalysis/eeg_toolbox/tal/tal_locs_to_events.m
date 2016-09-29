function events = tal_locs_to_events(allTalLocs)
% function events = tal_locs_2_events(allTalLocs)
%
% After running preptal, use this function to create an events
% struture that can be passed into tal2Region.
%
% INPUT
%        allTalLocs - path to file allTalLocs.txt, created by preptal.m
% 
% OUTPUT
%            events - events structure with the following fields:
%                     subject
%                     channel
%                     x
%                     y
%                     z
%                     Loc1
%                     Loc2
%                     Loc3
%                     Loc4
%                     Loc5
%                     Loc6
%                     isGood
%                     montage
%
% NOTE: The fields beginning "Loc" will be empty.  Run tal2Region
%       to fill in the empty fields.

fid = fopen('allTalLocs.txt','r');
c = textscan(fid,'%s%n%n%n%n%n%s');
f = {'subject','channel','x','y','z','isGood','montage'};

events = struct(f{1},c{1},f{2},[],f{3},[],f{4},[],f{5},[],...
         'Loc1',[],'Loc2',[],'Loc3',[],'Loc4',[],'Loc5',[],...
         'Loc6',[],f{6},[],f{7},c{7});
for e = 1:length(c{1})
    events(e).channel = c{2}(e);
    events(e).x = c{3}(e);
    events(e).y = c{4}(e);
    events(e).z = c{5}(e);
    events(e).isGood = c{6}(e);
end
fclose(fid)
