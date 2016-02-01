n = 3; % # vertical cells
m = 4; % # horizontal cells
vwalls = true(m - 1, n);
hwalls = true(n - 1, m);

pos = [1 1];


visited = false(n, m);
visited(pos(1),pos(2)) = true;

todo = {pos};
while ~isempty(todo)
  currpos = todo(end);
  valid = validmoves(currpos, visited);
  if isempty(valid)
    todo(end) = [];
  else
    next = pickone(valid);
    todo = [todo, next];
    [vwalls, hwalls] = breakwall(currpos, next);
  end
  visited(currpos(1),currpos(2)) = true;
end