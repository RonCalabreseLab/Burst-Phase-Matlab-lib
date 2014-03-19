function [  ] = actogramperiodplot( eventphases,  channelnames, actargs, axesID)
% actogramperiodplot(eventphases, channelnames, actargs, axesID) 
%  Draws an actogram for multiple channels of eventphases over period with the given drawing 
%  parameters (actargs) on axesID, if provided. channelnames, actargs and axesID are optional, 
%  though actargs must be present if axesID is passed. If axesID is not specified, the plot is drawn
%  on the current axes.
%  
% eventphases   : a matrix of columnar event phase data for some number of channels
% channelnames  : list of channel names (e.g. {'chan1', 'chan2', 'blabla'})
% actargs       : struct('stepheight', 1, 'marker', {{'+','o'}}, 'markerface', {{'r', [1 1 1]}}, ...
%                   'markeredge', {{'r', [1 1 1]}},'markersize', 10, 'duplicate', 'centered', 'showlegend', true)
%  stepheight   : the distance between each cycle (can be negative for a descending actogram)
%  marker       : options are:  + o * . x s d ^ v > < p h
%  markerface   : color may be specified by single letter: r g b c m y k w (see LineSpec) or [r g b]
%   note - this only applies to filled symbols.
%  markeredge   : color may be specified by single letter: r g b c m y k w (see LineSpec) or [r g b]
%   note - marker, markerface, markeredge may be left unspecifiedor as [] and defaults will be used
%          also, 'none' for markeredge will draw only the face, however this only applies to filled
%          symbols. Unfilled symbols will be invisible if markeredge is 'none'.
%  markersize   : base size of symbols used in points (default = 6pt)
%  duplicate    : plots data twice, either from -period to period    ('leftshift'), ('rightshift'),  
%                  no duplication ('none'), or -0.5*period to 1.5*period ('centered').                   
%  showlegend   : boolean variable - true will produce a legend, false will suppress the legend
%
% Example code calling actogramperiodplot:
%  %%
%  uiimport
%  % load data and column headers, place into data and colheaders as described above 
%
%  myargs = struct('stepheight', -1,...
%                  'marker', {{ '+','o', 'd' }},...
%                  'markerface', {{ 'r', [0 .5 .1], [.4 .2 .1] }}, ...
%                  'markeredge', {{ 'k', 'none', 'none' }}, ...
%                  'markersize', 10, 'duplicate', 'rightshift', 'showlegend', true)
%  actogramperiodplot(data, colheaders, myargs)
%  %%
% Damon Lamb
% adapted from actogramplot

%% Validate arguments
% if no existing axes are specified, set it to current axes
if exist('axesID', 'var') == 0
    axesID = gca;
end
axes(axesID);
hold all;
% if no channel names are specified, create names for them
if exist('channelnames', 'var') == 0 || isempty(channelnames)
    fprintf(1,'No channel names specified, using 1:number of channels in eventphases\n');
    channelnames = cell(size(eventphases,2),1);
    for chanind = 1:size(eventphases,2)
        channelnames{chanind} = sprintf('Ch %d', chanind);
    end
end
if length(channelnames) ~= size(eventphases,2)
   error('Number of channels in eventphases does not match channelnames'); 
else
    nchannels = length(channelnames);
end

% for chanind = 1:nchannels
%    if ndims(eventphases{chanind}) == 2
%        if size(eventphases{chanind},2) >1
%            % correct orientation to be a column vector
%            eventphases{chanind} = eventphases{chanind}';
%        end
%    else
%        error('eventphases does not appear to be correctly structured - should be cell array of column vectors');
%    end
% end

% % if channelnames are a row instead of a column, transpose
% if 1 == size(channelnames,1) && 1 < size(channelnames,2)
%     channelnames = channelnames';
% end

if exist('actargs', 'var') == 0
    stepheight = -1;
    marker     =  {'+' 'o' '*' '.' 'x' 's' 'd' '^' 'v' '>' '<' 'p' 'h'};
    markerface     =  {'r' 'g' 'b' 'c' 'm' 'y' 'k' };
    markeredge     =  {'r' 'g' 'b' 'c' 'm' 'y' 'k' };
    markersize = 10;
    duplicate  = 1; % centered: 0.5, none: 0, leftshift: -1, rightshift: 1
    showlegend = true;
else
    if actargs.stepheight == 0
        disp('Stepheight cannot be 0, changing to -1')
        stepheight = -1;
    else
        stepheight = actargs.stepheight;
    end
    if ~isfield(actargs, 'marker') || isempty(actargs.marker)
        marker     =  {'+' 'o' '*' '.' 'x' 's' 'd' '^' 'v' '>' '<' 'p' 'h'};
    else
        marker     =  actargs.marker;
    end
    markersize = actargs.markersize;
    if ~isfield(actargs, 'markerface') || isempty(actargs.markerface) 
        markerface     =  {'r' 'g' 'b' 'c' 'm' 'y' 'k' };
    else
        markerface     =  actargs.markerface;
    end
    if ~isfield(actargs, 'markeredge') || isempty(actargs.markeredge)
        markeredge     =  {'r' 'g' 'b' 'c' 'm' 'y' 'k' };
    else
        markeredge     =  actargs.markeredge;
    end
    %actargs.duplicate; % centered: 0.5, none: 0, leftshift: -1, rightshift: 1
    if strcmpi(actargs.duplicate, 'centered')
        duplicate  = 0.5;
    elseif strcmpi(actargs.duplicate, 'leftshift')
        duplicate  = -1;
    elseif strcmpi(actargs.duplicate, 'rightshift')
        duplicate  = 1;
    else
        duplicate  = 0;
    end
    showlegend = actargs.showlegend;
end
nmarker   = length(marker);
nmarkeredge   = length(markeredge);
nmarkerface   = length(markerface);
%% calculate and plot vectors for each channel
% setup plot variables
for chanind = 1:nchannels
    X = eventphases(:,chanind);
    if stepheight < 0
        Y = (size(eventphases,1):stepheight:1)';
    else
        Y = (1:stepheight:size(eventphases,1))';
    end
    ylimit = [min(Y), max(Y)];
    switch duplicate
        case {-1, 1}
            X = [X; X + duplicate];
            Y = [Y; Y - duplicate*stepheight];
        case 0.5 %centered
            %Y = [Y; Y(X<=.5)-stepheight; Y(X>.5)];
            %X = [X; X(X<=.5)+1; X(X>.5)-1];                          
            Y = [Y; Y-stepheight; Y+stepheight];
            X = [X; X+1; X-1];
    end
    Yselect = find(Y>=ylimit(1) & Y<=ylimit(2));
    X = X(Yselect);
    Y = Y(Yselect);  
    plot(X,Y,'LineStyle', 'none', ...
        'Marker', marker{mod(chanind-1,nmarker)+1}, ...
        'MarkerFaceColor', markerface{mod(chanind-1,nmarkerface)+1}, ...
        'MarkerEdgeColor', markeredge{mod(chanind-1,nmarkeredge)+1}, ...
        'MarkerSize', markersize);
    
end
ylim(ylimit+[-1 1])

if showlegend
    legend(channelnames)
end

end

