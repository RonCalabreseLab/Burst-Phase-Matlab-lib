function [colselect] = orWithin(header, categorylist)
% orWithin returns a boolean vector of columns which contain at least one
% entry in the categorylist
% (e.g. for header {'a' 'ba' 'c'}, categorylist {'b' 'c'} orWithin returns
% [0 1 1], whereas for categorylist{'a'} it returns [1 1 0]
% empty categorylist or 'all' in the first position on the list returns all
% ones (every column)
if isempty(categorylist) || strcmp(categorylist{1},'all')
    colselect = ones(size(header));
    return;
end
colselect = zeros(size(header));
for catind = 1:length(categorylist)
    colselect = colselect | ~cellfun('isempty', strfind(header, categorylist{catind}));
end
end
