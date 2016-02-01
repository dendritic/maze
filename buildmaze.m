function [hwalls, vwalls] = buildmaze(sz, drawbuild, entrances)

if nargin < 1 || isempty(sz)
  sz = [7 10];
end
if nargin < 2
  drawbuild = true;
end
if nargin < 3
  entrances = {[1 1] sz};
end
if ~isempty(entrances)
  start = entrances{1};
else
  start = [1 1];
end
m = sz(1); % n vertical cells
n = sz(2); % n horizontal cells

% arrays for presence of walls, wall direction by direction of normal:
% e.g  [  |  |  |  |
%         |  |  |  |
%         |  |  |  | ]
vwalls = true(m, n + 1);
hwalls = true(n, m + 1);
% Open walls to entrance cells
% NB: this would be nice as a reduce operation
for ei = 1:numel(entrances)
  [hwalls, vwalls] = makeentrance(hwalls, vwalls, entrances{ei});
end
visited = false(m, n); % cell visited state during build

figure;
updatevis = vis(gca);

% start from entry cell
visited(start(1),start(2)) = true;
todo = {start};
%% explore the space by making NSEW moves as a DFS
while ~isempty(todo)
  currpos = todo{end}; % check out next place to vist
  valid = validmoves(currpos, visited); % list valid moves at pos
  if isempty(valid) % no valid moves here, so remove from list causing a backtrack
    todo(end) = [];
  else % pick a valid move for the next position
    next = pickone(valid);
    todo = [todo, {next}];
    [hwalls, vwalls] = breakwall(hwalls, vwalls, currpos, next);
  end
  visited(currpos(1),currpos(2)) = true; % mark pos as visited
  
  if drawbuild
    updatevis(visited, currpos); % draw current map state
  end
end
updatevis(visited, currpos); % draw current map state

%% visualisation
  function upd = vis(axh)
    lastpos = start;
    %% draw visited map image and configure axes
    maph = imagesc(visited, 'Parent', axh);
    set(axh, 'CLim', [0 1], 'NextPlot', 'add', 'DataAspectRatio', [1 1 1],...
      'YLim', [0 size(visited, 1) + 1], 'XLim', [0 size(visited, 2) + 1]);
    colormap(axh, 'gray');
    %% marker at starting point
    posh = scatter(axh, lastpos(2), lastpos(1), 'o');
    %% draw walls
    [vwally, vwallx] = wallcoords(vwalls);
    [hwallx, hwally] = wallcoords(hwalls);
    vwallh = plot(axh, vwallx, vwally, 'r');
    hwallh = plot(axh, hwallx, hwally, 'r');
    %% function to update plots with next position
    upd = @update; 
    function update(visited, pos)
      set(maph, 'CData', visited); % update visited map image
      set(vwallh, {'visible'},... % update vertical walls visibility state
        arrayfun(@(on)iff(on, 'on', 'off'), vwalls(:), 'uni', false));
      set(hwallh, {'visible'},...% update horizontal walls visibility state
        arrayfun(@(on)iff(on, 'on', 'off'), hwalls(:), 'uni', false));
      set(posh, 'XData', pos(2), 'YData', pos(1)); % update marker for current pos
      % draw an extra line segment from previous pos to current
      plot(axh, [lastpos(2) pos(2)], [lastpos(1) pos(1)]);
      lastpos = pos; % save current pos for next time
      drawnow;
    end
  end

end
%% helper functions
function list = validmoves(pos, visited, candidates)
if nargin < 3
  candidates = {
    [-1  0] % N
    [ 1  0] % S
    [ 0  1] % E
    [ 0 -1] % W
    };
end

% a functional implementation
proposals = cellfun(@(d)pos + d, candidates, 'uni', false);
valididx = cellfun(...
  @(x)all(x >= 1) && all(x <= size(visited)) && ~visited(x(1),x(2)),...
  proposals);
list = proposals(valididx);

% % an alternative vectorised implementation - albeit a bit ugly
% [m, n] = size(visited);
% % create array of proposed positions, row-wise
% proposals = bsxfun(@plus, cell2mat(candidates), pos);
% bounded = proposals(all(...
%   proposals >= 1 & bsxfun(@le, proposals, [m n]),...
%   2), :); % select rows with both columns bounded
% boundedidx = sub2ind([m n], bounded(:,1), bounded(:,2));
% % select unvisited cells
% list = bounded(~visited(boundedidx),:);
% list = num2cell(list, 2); % convert to a list

end

function move = pickone(moves)
% just randomly pick a move with uniform probability
move = moves{randi(size(moves, 1))};
end

function [hwalls, vwalls] = breakwall(hwalls, vwalls, p, q)
d = abs(p - q);
breakidx = max(p, q);
if d(1) == 1 && d(2) == 0 % horizontal wall between vertically stacked cells
  hwalls(breakidx(2),breakidx(1)) = false;
elseif d(1) == 0 && d(2) == 1 % vertical wall between horizontally stacked cells
  vwalls(breakidx(1),breakidx(2)) = false;
else
  error('Coordinate pair do not specify vertically or horizontally adjacent cells');
end
end

function [hwalls, vwalls] = makeentrance(hwalls, vwalls, intocell)
% break exterior wall adjacent to a cell
if intocell(1) == 1 % entry along top
  [hwalls, vwalls] = breakwall(hwalls, vwalls, intocell, intocell + [-1 0]);
elseif intocell(1) == size(hwalls, 2) - 1 % entry along bottom
  [hwalls, vwalls] = breakwall(hwalls, vwalls, intocell, intocell + [1 0]);
elseif intocell(2) == 1 % entry along left
  [hwalls, vwalls] = breakwall(hwalls, vwalls, intocell, intocell + [0 -1]);
elseif intocell(2) == size(vwalls, 2) - 1 % entry along right
  [hwalls, vwalls] = breakwall(hwalls, vwalls, intocell, intocell + [0 1]);
else % don't break wall as not adjancent to exterior but warn
  warning('Entry point not adjacent to exterior wall');
end
end

function [ends, offsets] = wallcoords(walls)
% build sets of coordinates for wall line segments
[ends, offsets] = ndgrid(1:size(walls, 1), (1:size(walls, 2)) - 0.5);
ends = cat(2, ends(:) - .5, ends(:) + .5)';
offsets = cat(2, offsets(:), offsets(:))';
end

function ev = iff(cond, evalTrue, evalFalse) % emulate a conditional expression
% NB: of course this does not have the usual correct semantics as in this
% case eval expressions are both always evaluated
if cond, ev = evalTrue; else ev = evalFalse; end
end