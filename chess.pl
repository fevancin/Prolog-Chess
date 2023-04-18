% The board is represented by a list of lists, in which each square is 'empty' or a couple (color, type).
empty_board([
    [empty, empty, empty, empty, empty, empty, empty, empty],
    [empty, empty, empty, empty, empty, empty, empty, empty],
    [empty, empty, empty, empty, empty, empty, empty, empty],
    [empty, empty, empty, empty, empty, empty, empty, empty],
    [empty, empty, empty, empty, empty, empty, empty, empty],
    [empty, empty, empty, empty, empty, empty, empty, empty],
    [empty, empty, empty, empty, empty, empty, empty, empty],
    [empty, empty, empty, empty, empty, empty, empty, empty]
]).

initial_board([
    [[black, rook], [black, knight], [black, bishop], [black, queen], [black, king], [black, bishop], [black, knight], [black, rook]],
    [[black, pawn], [black, pawn], [black, pawn], [black, pawn], [black, pawn], [black, pawn], [black, pawn], [black, pawn]],
    [empty, empty, empty, empty, empty, empty, empty, empty],
    [empty, empty, empty, empty, empty, empty, empty, empty],
    [empty, empty, empty, empty, empty, empty, empty, empty],
    [empty, empty, empty, empty, empty, empty, empty, empty],
    [[white, pawn], [white, pawn], [white, pawn], [white, pawn], [white, pawn], [white, pawn], [white, pawn], [white, pawn]],
    [[white, rook], [white, knight], [white, bishop], [white, queen], [white, king], [white, bishop], [white, knight], [white, rook]]
]).

% small helper function for switching color.
other(white, black) :- !.
other(black, white).

% The square matching is computed via nth0. This predicate works in both directions (X,Y)->square and square->(X,Y).
is_square(Board, X, Y, Square) :- nth0(X, Board, Row), nth0(Y, Row, Square).

% helper predicate for replacment of an element in al list.
% replace(List, Index, Element, NewList).
replace([_ | Tail], 0, Element, [Element | Tail]) :- !.
replace([Head | Tail], N, Element, [Head | NewTail]) :- N2 is N - 1, replace(Tail, N2, Element, NewTail).

% This predicate compute a new board with a certain (X,Y) square replaced. Pawns are promoted to queens.
set_square(Board, 0, Y, [white, pawn], NewBoard) :- !,
    nth0(0, Board, Row),
    replace(Row, Y, [white, queen], NewRow),
    replace(Board, 0, NewRow, NewBoard).
set_square(Board, 7, Y, [black, pawn], NewBoard) :- !,
    nth0(7, Board, Row),
    replace(Row, Y, [black, queen], NewRow),
    replace(Board, 7, NewRow, NewBoard).
set_square(Board, X, Y, Square, NewBoard) :-
    nth0(X, Board, Row),
    replace(Row, Y, Square, NewRow),
    replace(Board, X, NewRow, NewBoard).

% A movement is reconduct to a double replacement: 'source' with 'empty' and 'destination' with 'source'.
move(Board, SourceX, SourceY, DestinationX, DestinationY, NewBoard) :-
    is_square(Board, SourceX, SourceY, Square),
    set_square(Board, SourceX, SourceY, empty, TempBoard),
    set_square(TempBoard, DestinationX, DestinationY, Square, NewBoard).

% Predicate true if there are no pieces from source to destination.
% The destination could contain 'empty' or a piece of the opposite color of the source (that could be taken).
is_valid_trail(Board, SourceX, SourceY, DestinationX, DestinationY) :-
    is_square(Board, SourceX, SourceY, [Color, _]),
    DirectionX is sign(DestinationX - SourceX), DirectionY is sign(DestinationY - SourceY), % calc of the direction vector
    NewX is SourceX + DirectionX, NewY is SourceY + DirectionY,
    trail_helper(Board, Color, NewX, NewY, DestinationX, DestinationY, DirectionX, DirectionY).

% Helper of the previous predicate with a recursive definition.
trail_helper(Board, Color, DestinationX, DestinationY, DestinationX, DestinationY, _, _) :- !,
    (is_square(Board, DestinationX, DestinationY, empty) ; (other(Color, OtherColor), is_square(Board, DestinationX, DestinationY, [OtherColor, _]))).
trail_helper(Board, Color, SourceX, SourceY, DestinationX, DestinationY, DirectionX, DirectionY) :-
    is_square(Board, SourceX, SourceY, empty),
    NewX is SourceX + DirectionX, NewY is SourceY + DirectionY, % Each new call is obtained thanks to the directions provided.
    trail_helper(Board, Color, NewX, NewY, DestinationX, DestinationY, DirectionX, DirectionY).

% below are all the different move computations. Nondeterminate predicates in order to obtain all possibilities.
% King, knights and pawns don't require 'is_valid_trail' because they move with trails of one step.

% king
can_move(Board, Color, X, Y, NewX, NewY) :- is_square(Board, X, Y, [Color, king]),
    nth0(_, [0, 1, 2, 3, 4, 5, 6, 7], NewX), nth0(_, [0, 1, 2, 3, 4, 5, 6, 7], NewY),
    \+ (NewX == X, NewY == Y), abs(NewX - X) =< 1, abs(NewY - Y) =< 1,
    (is_square(Board, NewX, NewY, empty) ; (other(Color, OtherColor), is_square(Board, NewX, NewY, [OtherColor, _]))).

% queen
can_move(Board, Color, X, Y, NewX, NewY) :- is_square(Board, X, Y, [Color, queen]),
    nth0(_, [0, 1, 2, 3, 4, 5, 6, 7], NewX), nth0(_, [0, 1, 2, 3, 4, 5, 6, 7], NewY),
    \+ (NewX == X, NewY == Y), (abs(NewX - X) =:= abs(NewY - Y) ; ((NewX == X, NewY \= Y) ; (NewX \= X, NewY == Y))),
    is_valid_trail(Board, X, Y, NewX, NewY).

% rook
can_move(Board, Color, X, Y, NewX, NewY) :- is_square(Board, X, Y, [Color, rook]),
    nth0(_, [0, 1, 2, 3, 4, 5, 6, 7], NewX), nth0(_, [0, 1, 2, 3, 4, 5, 6, 7], NewY),
    ((NewX == X, NewY \= Y) ; (NewX \= X, NewY == Y)),
    is_valid_trail(Board, X, Y, NewX, NewY).

% knight
can_move(Board, Color, X, Y, NewX, NewY) :- is_square(Board, X, Y, [Color, knight]),
    nth0(_, [0, 1, 2, 3, 4, 5, 6, 7], NewX), nth0(_, [0, 1, 2, 3, 4, 5, 6, 7], NewY),
    ((abs(NewX - X) =:= 2, abs(NewY - Y) =:= 1) ; (abs(NewX - X) =:= 1, abs(NewY - Y) =:= 2)),
    (is_square(Board, NewX, NewY, empty) ; (other(Color, OtherColor), is_square(Board, NewX, NewY, [OtherColor, _]))).

% bishop
can_move(Board, Color, X, Y, NewX, NewY) :- is_square(Board, X, Y, [Color, bishop]),
    nth0(_, [0, 1, 2, 3, 4, 5, 6, 7], NewX), nth0(_, [0, 1, 2, 3, 4, 5, 6, 7], NewY),
    \+ (NewX == X, NewY == Y), abs(NewX - X) =:= abs(NewY - Y),
    is_valid_trail(Board, X, Y, NewX, NewY).

% pawn
can_move(Board, Color, X, Y, NewX, NewY) :- is_square(Board, X, Y, [Color, pawn]),
    pawn_direction(Color, Direction),
    nth0(_, [0, 1, 2, 3, 4, 5, 6, 7], NewX), nth0(_, [0, 1, 2, 3, 4, 5, 6, 7], NewY),
    ((NewX =:= X + Direction, NewY = Y, is_square(Board, NewX, NewY, empty)) ; % move forward
    (X == 6, Color == white, NewX == 4, NewY = Y, is_square(Board, 5, NewY, empty), is_square(Board, 4, NewY, empty)) ; % initial double move of white
    (X == 1, Color == black, NewX == 3, NewY = Y, is_square(Board, 2, NewY, empty), is_square(Board, 3, NewY, empty)) ; % initial double move of black
    (NewX =:= X + Direction, NewY =:= Y + 1, other(Color, OtherColor), is_square(Board, NewX, NewY, [OtherColor, _])) ; % eat right
    (NewX =:= X + Direction, NewY =:= Y - 1, other(Color, OtherColor), is_square(Board, NewX, NewY, [OtherColor, _]))). % eat left

pawn_direction(white, -1) :- !.
pawn_direction(black, 1).

% The board value is the sum of all the pieces with their respective values and the value of their position.
% Position are valued with the sum of their X and Y values as: 1, 2, 3, 4, 4, 3, 2, 1.
board_value(Board, Value) :- board_helper(Board, 0, Value).

% Sum of all rows.
board_helper([], _, 0) :- !.
board_helper([Row | Rest], X, Value) :- row_value(Row, X, 0, RowValue), X1 is X + 1, board_helper(Rest, X1, RestValue), Value is RowValue + RestValue.

% The value of a specific row is the sum of each square value.
row_value([], _, _, 0) :- !.
row_value([empty | Rest], X, Y, Value) :- !, Y1 is Y + 1, row_value(Rest, X, Y1, Value).
row_value([[Color, Type] | Rest], X, Y, Value) :- Y1 is Y + 1, row_value(Rest, X, Y1, RestValue),
    piece_value(Type, PieceValue), color_multiplier(Color, Multiplier),
    coord_value(X, XValue), coord_value(Y, YValue),
    Value is (PieceValue + XValue + YValue) * Multiplier + RestValue. % The multiplier is used for tracking white and black pieces.

% Kings are valued so much that render the win condition trivial as a simple bound check.
% If the board value exits from (-10'000, 10'000) the game is ended.
piece_value(king, 100000) :- !.
piece_value(queen, 90) :- !.
piece_value(rook, 50) :- !.
piece_value(knight, 30) :- !.
piece_value(bishop, 30) :- !.
piece_value(pawn, 10).

% White correspond to positive values, black to negatives.
color_multiplier(white, 1) :- !.
color_multiplier(black, -1).

% 0,7 are valued 1, 1,6 are valued 2, 2,5 are valued 3 and 3,4 are valued 4.
coord_value(0, 1) :- !.
coord_value(1, 2) :- !.
coord_value(2, 3) :- !.
coord_value(3, 4) :- !.
coord_value(4, 4) :- !.
coord_value(5, 3) :- !.
coord_value(6, 2) :- !.
coord_value(7, 1).

% Predicate that extract the couple (move,value) with the best value given the turn color (black strives for negative values, white for positives).
extract_best_move([], _, none, 0) :- !.
extract_best_move([[Move, Value] | Rest], Color, BestMove, BestValue) :- extract_helper(Rest, Color, Move, Value, BestMove, BestValue).

extract_helper([], _, TempMove, TempValue, TempMove, TempValue) :- !.
extract_helper([[Move, Value] | Rest], Color, _, TempValue, BestMove, BestValue) :- color_multiplier(Color, Multiplier), Value * Multiplier > TempValue * Multiplier, !, extract_helper(Rest, Color, Move, Value, BestMove, BestValue).
extract_helper([_ | Rest], Color, TempMove, TempValue, BestMove, BestValue) :- extract_helper(Rest, Color, TempMove, TempValue, BestMove, BestValue).

% Min-max search implementation. This specific callable predicate doesn't make any moves in order to avoid branching in the top-most level.
search(Board, Color, Depth, BestMove, BestValue) :-
    findall([ChildBestMove, ChildBestValue], search_helper(Board, Color, Depth, ChildBestMove, ChildBestValue), ChildResults),
    extract_best_move(ChildResults, Color, BestMove, BestValue),
    BestMove = move(A, B, C, D),
    format("[~a, ~a, ~a, ~a]", [A, B, C, D]).

% Base case of max depth reach.
search_helper(Board, _, 0, none, Value) :- !, board_value(Board, Value).
% Base case of a checkmate. Board values are computed assigning a very big number to kings.
search_helper(Board, _, _, none, Value) :- board_value(Board, Value), (Value > 10000 ; Value < -10000), !.
% Actual recursive search.
search_helper(Board, Color, Depth, move(SourceX, SourceY, DestinationX, DestinationY), BestValue) :-
    other(Color, ChildColor),
    ChildDepth is Depth - 1,
    can_move(Board, Color, SourceX, SourceY, DestinationX, DestinationY), % Non-deterministic step
    move(Board, SourceX, SourceY, DestinationX, DestinationY, ChildBoard), % apply the current chosen move to obtain ChildBoard
    findall([ChildBestMove, ChildBestValue], search_helper(ChildBoard, ChildColor, ChildDepth, ChildBestMove, ChildBestValue), ChildResults), % recursive search
    extract_best_move(ChildResults, Color, _, BestValue).