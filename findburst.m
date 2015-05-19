function firstlastinds = findburst(spiketimes, maxISI, minSPB, minIBI, ...
                                   starttime, endtime, debug)

% findburst - Identifies bursts with given constraints.
%
% Usage: 
% firstlastinds = findburst(spiketimes, maxISI, minSPB, minIBI, starttime, endtime)
%
% Parameters:
%   spiketimes: A list.
%   maxISI: Maximum interspike interval (ISI).
%   minSPB: Minimum number of spikes within each burst.
%   minIBI: Minimum ISI tolerated in the inter-burst interval (IBI).
%   starttime: Defaults to the first spiketime-2*maxISI.
%   endtime: Defaults to the final spiketime+2*maxISI.
%   debug: If 1, print reason for failure.
%
% Description:
%   If a burst begins within maxISI of starttime or endtime, it is removed
% as we do not have the full burst to work with. By default all bursts will
% be identified, including those at the edge of the provided data.
%
% Author: Damon Lamb
%
% Modified by: 
% - Cengiz Gunay <cengique@users.sf.net> 2015/04/27
%   Added IBI parameter and condition. Added debug flag.

debug = defaultValue('debug', false);

% if too few spikes in the input then short circuit to return
if length(spiketimes) < minSPB
   firstlastinds = [];
   return;
end

% initialize optional arguments if not provided
if exist('starttime', 'var') == 0
    starttime = spiketimes(1) - 2*maxISI;
end
if exist('endtime', 'var') == 0
    endtime = spiketimes(end) + 2*maxISI;
end

% Begin main code:

% save offset index for first spiketime used so firstlast matrix indexes the full spiketime train
firstvalidspike_offset = find(spiketimes >= starttime, 1, 'first') -1;

% trim spiketimes to begin/end with starttime & endtime
spiketimes = spiketimes((spiketimes >= starttime) & (spiketimes <= endtime));

% reduce to valid spikes - spikes with preceeding ISI less than maxISI
isis = diff(spiketimes);
validspikeinds = find(isis <= maxISI);

% look into inter-burst intervals
ibispikes = find(isis > maxISI);

% if spikes don't slow enough in IBI, return
if max(isis(ibispikes)) < minIBI
  if debug
    warning([ 'Max ISI in the IBI region ' num2str(max(isis(ibispikes)))  ...
              ' is below minIBI=' num2str(minIBI) '.' ]);
  end
  firstlastinds = [];
  return;
end

% break into bursts within validspikes
vspkindinds = [0; diff(validspikeinds)==1; 0]'; 
startinds = strfind(vspkindinds,[0 1]); % find start of burst (transition from 0 to 1)
endinds = strfind(vspkindinds,[1 0]);   % find end of burst (transition from 1 to 0)

% If we have no bursts then return
if (isempty(startinds) || isempty(endinds))
  if debug
    warning('Found no bursts.');
  end
  firstlastinds = [];
  return;
end

% if first spike is within first burst
if (validspikeinds(startinds(1)) == 1)
    % and spike is within maxISI of starttime
    if (spiketimes(validspikeinds(startinds(1)))-maxISI <= starttime)
        % then the first burst is invalid, so is trimmed
        startinds = startinds(2:end);
        endinds = endinds(2:end);
    end
end

% If we have no bursts remaining then return
if (isempty(startinds) || isempty(endinds))
  if debug
    warning('Found no bursts after removing first one.');
  end
  firstlastinds = [];
  return;
end

% if last spike is within last burst
if (validspikeinds(endinds(end)) == length(spiketimes) - 1)
    % and spike is within maxISI of endtime
    if (spiketimes(validspikeinds(endinds(end)))+maxISI >= endtime)
        % then the first burst is invalid, so is trimmed
        startinds = startinds(1:end-1);
        endinds = endinds(1:end-1);
    end
end

% If we have no bursts remaining then return
if (isempty(startinds) || isempty(endinds))
  if debug
    warning('Found no bursts after removing last one.');
  end
  firstlastinds = [];
  return;
end

% trim out bursts which are too short (fewer than minSPB spikes)
longburstsinds = find(endinds-startinds>=minSPB);
startinds = startinds(longburstsinds);
endinds = endinds(longburstsinds);

% If we have no bursts remaining then return
if (isempty(startinds) || isempty(endinds))
  if debug
    warning(['No bursts left after trimming ones with fewer spikes ' ...
             'than ' num2str(minSPB) '.' ]);
  end
  firstlastinds = [];
  return;
end

startinds = validspikeinds(startinds);
endinds = validspikeinds(endinds) + 1;

% construct matrix of first and last bursts, with row index = burst number, colums: first, last
firstlastinds = [startinds,endinds]+firstvalidspike_offset;
