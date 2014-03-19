function [  ] = phaseplot(stats, channelnames, drawingargs, axesID)
%PHASEPLOT plot cartesian phase diagram (mean +/- std) from provided stats
%  phaseplot(stats, channelnames, drawingargs, axesID)
%  stats structure which has the form: stats.{mean, std}.{phase, first, last, duty, period}
%  defaults for drawing arguments:
%  drawingargs = struct('barheight', 1, 'gapheight', 0.5, 'barcolor', [1 1 0], 'phasecolor', [0 0 0], ...
%     'stdcolor', [0 0 0], 'stdbar', [0 1], 'stdbarendcap', 0.3, 'chanoffset', 0)
%  results in yellow bars 1 unit high, with a gap of 0.5 of a unit, with
%  black phase marks and std bars, the latter of which are facing 'out'
%  only and whose end caps are 0.3 units high
% stdbar can change to accomodate only left or right std bars
% [1 0] is just 'normal' right facing, except first spike - first and last bars face out
% [-1 0] is just flipped - left facing, except for first spike - end bars face in
% [1 -1] is both; swapped values have no effect ([0 1] is the same as [1 0])
% Color is in the form [r g b] on a scale of 0-1 (so [1 0 0] is full red)
% 
% If axesID is provided the plot is drawn to the given axes with an offset as specified as
% chanoffset in the drawingargs structure; this slides the new additions to the phase plot by
% chanoffset number of channels (ie, after plotting 6 channels, if you wish to add another set with
% a gap, you could use channeloffset = 7.2, which would result in 1.2*(barheight+gapheight) space
% between the two sets of channels. Sets of channels can be plotted interleaved, although this
% function will throw an error if the bars overlap entirely.
%
% Damon Lamb, Aug 2010. V1.0.1

% TODO: extend options to include line thicknesses, etc.

%% Validate arguments
% if no existing axes are specified, set it to current axes
if exist('axesID', 'var') == 0
    axesID = gca;
end
axes(axesID);
% if no channel names are specified, create names for them
if exist('channelnames', 'var') == 0
    fprintf(1,'No channel names specified, using 1:stats.numchannels\n');
    channelnames = cell(stats.numchannels,1);
    for chanind = 1:stats.numchannels
        channelnames{chanind} = sprintf('Ch %d', chanind);
    end
end
% invert channelnames (plots are drawn from top to bottom, labels bottom to top
for chanind = 1:floor(stats.numchannels/2)
    chtmp = channelnames{chanind};
    channelnames{chanind} = channelnames{stats.numchannels + 1 - chanind};
    channelnames{stats.numchannels + 1 - chanind} = chtmp;
end
% if channelnames are a row instead of a column, transpose
if 1 == size(channelnames,1) && 1 < size(channelnames,2)
    channelnames = channelnames';
end
if exist('drawingargs', 'var') == 0
    barheight    = 1;
    gapheight    = .5;
    patchcolor   = [1 1 0];
    phasecolor   = [.9 0 0];
    stdcolor     = [0 0 0];
    stdbardir    = [0 1];
    stdbarendcap = .15;
    nchanoffset  = 0;
else
    barheight    = drawingargs.barheight;
    gapheight    = drawingargs.gapheight;
    patchcolor   = drawingargs.barcolor;
    phasecolor   = drawingargs.phasecolor;
    stdcolor     = drawingargs.stdcolor;
    stdbardir    = drawingargs.stdbar;
    stdbarendcap = drawingargs.stdbarendcap / 2; % endcap is drawn up and down from center line
    nchanoffset  = drawingargs.chanoffset;
end

ystepsize = barheight+gapheight;
% note:
% patch([x1 x2  x3 x4], [y1 y1 y3 y4] , color)
% color is in form of [r g b], scale is 0-1
%% Draw phase plot - bars, std marks, etc (+/- 1)
for xoffset = -1:1
    for chind = 1:stats.numchannels
        % draw main box
        patch([stats.mean.first(chind) [1 1]*stats.mean.last(chind) stats.mean.first(chind)]+xoffset, ...
            -[1 1 1 1]*(chind+nchanoffset)*(ystepsize)-[barheight barheight 0 0], patchcolor)
        % draw phase line
        line([1 1]*stats.mean.phase(chind)+xoffset, ...
            -[1 1]*(chind+nchanoffset)*(ystepsize)-[barheight 0], 'color', phasecolor)
        % draw +/- std lines
        yvals = [stats.mean.phase(chind) stats.std.phase(chind); ...  % ordered phase, first, last
            stats.mean.first(chind) stats.std.first(chind); ...  % to 'flip' first std bar
            stats.mean.last(chind)  stats.std.last(chind)];
        for stdind = 1:3
            stdbar = (-1)^(stdind-1)*stdbardir; % flips the direction of the std bars for the first spike
            % draw std line
            line(stdbar*yvals(stdind, 2)+yvals(stdind, 1)+xoffset, ...
                -[1 1]*(chind+nchanoffset)*(ystepsize)-barheight*[.5 .5], 'color', stdcolor)
            for i=1:2 % and end bar(s)
                line( stdbar(i)*[1 1]*yvals(stdind, 2) + yvals(stdind, 1) + xoffset, ...
                    -[1 1]*(chind+nchanoffset)*(ystepsize)-barheight*[.5-stdbarendcap .5+stdbarendcap], 'color', stdcolor)
            end
        end
    end
end

%% Update axes tick marks/labels and xlimit

xlim([-1 1])
set(axesID, 'XTick', -1:.25:1)
set(axesID, 'XTickLabel', -1:.25:1)

% yticks and labels
ystartnew = -(stats.numchannels+nchanoffset)*(ystepsize) - barheight;
yendnew = -(nchanoffset+1)*(ystepsize);
ystepnew = (ystepsize);
textoffset = barheight/2;

yticknew = (ystartnew:ystepnew:yendnew)+textoffset;
ylimnew = [ystartnew-gapheight yendnew+gapheight];

ylabelold = get(axesID, 'YTickLabel');
ytickold = get(axesID, 'YTick');
ylimold = get(axesID, 'Ylim');

if iscell(ylabelold) % preserve existing ticks, labels
    ylabels = [ylabelold;channelnames];
    if overlaps(yticknew, ytickold, barheight/2)
        error('Error: Labels overlap, unable to continue drawing');
    end
    yticks = [ytickold yticknew];
    [yticks, sortedindices] = sort(yticks);
    ylabels = ylabels(sortedindices);
    ylims = [min(ylimold(1), ylimnew(1)) max(ylimold(end), ylimnew(end))];
else
    ylabels = channelnames;
    yticks = yticknew;
    ylims = ylimnew;
end

% y lims should be from 0 to current number of channels + channeloffset
ylim(ylims)
set(axesID, 'YTick', yticks)
set(axesID, 'YTickLabel', ylabels)

end
%% duplicate: quick function to check for duplicates (in tick mark lists)
function overlap = overlaps(vec1, vec2, mingap)
overlap = false;
for i = 1:length(vec1)
    for j = 1:length(vec2)
        if abs(vec1(i) - vec2(j)) <= mingap
            overlap = true;
            return;
        end
    end
end
end
