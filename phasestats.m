function [stats, intermediate_data] = phasestats(firstlast, medianspike, phaserefind)
% PHASESTATS(firstlast, medianspike, phaserefind)
%
%  Arguments:
%     firstlast   : 1xn cell array of mx2 matrix of the spike time of the first and last spikes 
%     medianspike : 1xn cell array of mx2 matrix of the spike time of the median spike
%     phaserefind : channel index to use as phase reference
%
% expect data as a cell array (1-d) of n cells, where each contains column vector data for channel n.
%
% Returned stats are defined as:
%  period :  m+1th median spike - mth median spike
%
%  phase  :  (mth median spike of nth channel - mth median spike of
%              reference channel) / period of mth burst
%
%  first  :  (mth first spike of nth channel - mth median spike of
%              reference channel) / period of mth burst
%
%  last   :  (mth last spike of nth channel - mth median spike of
%              reference channel) / period of mth burst
%  
%  duty   :  (mth first spike - mth last spike)
%
%  results are returned as a structure organized as row vectors (each column is one channel)
%          stats.{mean, std}.{phase, first, last, duty, period}
%
%  The number of phase reference bursts may be one higher than the other channels, allowing for use 
%  of all available bursts, although the number of periods analyzed is one fewer than the minimum 
%  number of bursts across the other channels.
%
%   Damon Lamb Aug 2010, V0.9.10
%



% TODO: autocorrect orientation of arguments

%% validate arguments (same number of bursts, etc.)
% for each cell array of data, verify # channels is equal, set nchannels to minimum burst dimension
flchancount = length(firstlast);
mschancount = length(medianspike);
if ~(flchancount == mschancount)
    error('Channel counts do not match between firstlast, medianspike')
else
    nchannels = flchancount;
end

% use cellfun (calls specified function over elements of a cell data type) to ensure dimensions are
% correct for the following code - column data vectors for each channel
fldim = cellfun('size', firstlast,2);
msdim = cellfun('size', medianspike,2);

if ~(max(fldim) == 2 && min(fldim) == 2)
    error('Orientation and/or structure of firstlast argument is not two column vectors for each channel')
end
if ~(max(msdim) == 1 && min(msdim) == 1)
    error('Orientation and/or structure of medianspike argument is not a single column vector for each channel')
end   


% find the minimum number of bursts for each burst argument, verify they match.
fldim = cellfun('size', firstlast,1); % First Last dimension
msdim = cellfun('size', medianspike,1);% Median spike dimension

if min(fldim == msdim) == 0 % this should certainly never happen so long as valid data is passed
    error('Different number of bursts between arguments, please verify arguments')
end

%% Calculate number of bursts to work with

nbursts = min(msdim);
nburstsph = nbursts;
if msdim(phaserefind) >= nbursts + 1
    nburstsref = nbursts + 1; % it is possible to use an extra burst of the phase ref channel
else
    nburstsref = nbursts;
    nbursts = nbursts - 1;
end

%% Calculate period, phasing, duty cycle, and stats
period = zeros(nburstsph-1, nchannels);

phase = zeros(nbursts, nchannels);
first = zeros(size(phase));
last = zeros(size(phase));
% phase ref period (the period that matters for calculations)
prperiod = diff(medianspike{phaserefind}(1:nburstsref));

for i=1:nchannels
    period(:,i)=diff(medianspike{i}(1:nburstsph));
end


for i=1:nchannels
    phase(:,i)= (medianspike{i}(1:nbursts)-medianspike{phaserefind}(1:nbursts))./ prperiod;
    first(:,i)= (firstlast{i}(1:nbursts,1)-medianspike{phaserefind}(1:nbursts))./ prperiod;
    last(:,i)=  (firstlast{i}(1:nbursts,2)-medianspike{phaserefind}(1:nbursts))./ prperiod;
end

duty=last-first;
means = struct('phase', mean(phase), 'first', mean(first), 'last', mean(last), 'duty', mean(duty), 'period', mean(period));
stds = struct('phase', std(phase), 'first', std(first), 'last', std(last), 'duty', std(duty), 'period', std(period));
stats = struct('mean', means, 'std', stds, 'ref_chan_ind',phaserefind, 'numchannels', nchannels);

intermediate_data = struct('phase', phase, 'first', first, 'last', last, 'period', period, 'duty', duty);

end

