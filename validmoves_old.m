function list = validmoves_old(pos, visited)
% moves = [
%   -1  0 % N
%    1  0 % S
%    0  1 % E
%    0 -1 % W
%   ];
list = {};
if pos(1) > 1 && ~visited(pos(1)-1,pos(2)) % can go north
  list = [list; [pos(1)-1, pos(2)]];
end
if pos(1) < size(visited, 1) && ~visited(pos(1)+1, pos(2)) % can go south
  list = [list; [pos(1)+1, pos(2)]];
end
if pos(2) < size(visited, 2) && ~visited(pos(1), pos(2)+1) % can go east
  list = [list; [pos(1), pos(2)+1]];
end
if pos(2) > 1 && ~visited(pos(1), pos(2)-1) % can go west
  list = [list; [pos(1), pos(2)-1]];
end
end