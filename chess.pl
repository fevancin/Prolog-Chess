:- use_module(library(lists)).

% utility for the color swap.
other(white, black) :- !.
other(black, white).

% Square is Board[X][Y].
getSquare(X, Y, Board, Square) :- nth1(X, Board, Row), nth1(Y, Row, Square).

% substitute(N, List, Elem, NewList)
% replace element N of List with Elem, returning the new list NewList.
substitute(1, [_ | T], Elem, [Elem | T]) :- !.
substitute(N, [H | T], Elem, [H | NewTail]) :- N2 is N - 1, substitute(N2, T, Elem, NewTail).

% place a certain Square in Board[X][Y], returning the new board NewBoard.
setSquare(X, Y, Board, Square, NewBoard) :-
  nth1(X, Board, Row),
  substitute(Y, Row, Square, NewRow),
  substitute(X, Board, NewRow, NewBoard).

% the board is an 8x8 list of lists, containing 'empty' or a two-sized list [color, type].
getStartingBoard([
  [[black,rook], [black,knight], [black,bishop], [black,queen], [black,king], [black,bishop], [black,knight], [black,rook]],
  [[black,pawn], [black,pawn],   [black,pawn],   [black,pawn],  [black,pawn], [black,pawn],   [black,pawn],   [black,pawn]],
  [empty,        empty,          empty,          empty,         empty,        empty,          empty,          empty       ],
  [empty,        empty,          empty,          empty,         empty,        empty,          empty,          empty       ],
  [empty,        empty,          empty,          empty,         empty,        empty,          empty,          empty       ],
  [empty,        empty,          empty,          empty,         empty,        empty,          empty,          empty       ],
  [[white,pawn], [white,pawn],   [white,pawn],   [white,pawn],  [white,pawn], [white,pawn],   [white,pawn],   [white,pawn]],
  [[white,rook], [white,knight], [white,bishop], [white,queen], [white,king], [white,bishop], [white,knight], [white,rook]]
]).

% modify Board executing the move [XFrom, YFrom, XTo, YTo]. Returns a new board NewBoard.
% the first two predicates are for handling queen promotion
makeMove(Board, [2, YFrom, 1, YTo], NewBoard) :-
  getSquare(2, YFrom, Board, [white, pawn]), !, % if white pawn about to reach first row
  setSquare(2, YFrom, Board, empty, TempBoard),
  setSquare(1, YTo, TempBoard, [white, queen], NewBoard).
makeMove(Board, [7, YFrom, 8, YTo], NewBoard) :-
  getSquare(7, YFrom, Board, [black, pawn]), !,  % if black pawn about to reach last row
  setSquare(7, YFrom, Board, empty, TempBoard),
  setSquare(8, YTo, TempBoard, [black, queen], NewBoard).
makeMove(Board, [XFrom, YFrom, XTo, YTo], NewBoard) :-
  getSquare(XFrom, YFrom, Board, Square),
  setSquare(XFrom, YFrom, Board, empty, TempBoard),
  setSquare(XTo, YTo, TempBoard, Square, NewBoard).

% value of every piece type
pieceValue([_,king], 1000) :- !.
pieceValue([_,queen], 9) :- !.
pieceValue([_,rook], 5) :- !.
pieceValue([_,knight], 3) :- !.
pieceValue([_,bishop], 3) :- !.
pieceValue([_,pawn], 1).

% indexes of square have an intrinsic value
v(1, 1) :- !. v(2, 2) :- !. v(3, 3) :- !. v(4, 4) :- !.
v(8, 1) :- !. v(7, 2) :- !. v(6, 3) :- !. v(5, 4).

% sum of X and Y value gives the square value
squareValue([X, Y], Value) :- v(X, XValue), v(Y, YValue), Value is XValue + YValue.

isPiece([_, _]).
isSameColor(Color, [Color, _]).

myPartition(_, [], [], []) :- !.
myPartition(Rule, [H | T], [H | TrueTail], ListFalse) :- call(Rule, H), !, myPartition(Rule, T, TrueTail, ListFalse).
myPartition(Rule, [H | T], ListTrue, [H | FalseTail]) :- myPartition(Rule, T, ListTrue, FalseTail).

% predicate that specify the value Value of the board Board
evaluate(Turn, Board, Value) :-
  append(Board, List), include(isPiece, List, Pieces),
  partition(isSameColor(Turn), Pieces, MyPieces, OtherPieces),

  maplist(pieceValue, MyPieces, MyValues), % combined value of my pieces
  sum_list(MyValues, MyValue),

  maplist(pieceValue, OtherPieces, OtherValues), % combined value of enemy pieces
  sum_list(OtherValues, OtherValue),

  findall([X, Y], getSquare(X, Y, Board, [Turn, _]), MyPieceCoordinates), % combined value of my piece coordinates
  maplist(squareValue, MyPieceCoordinates, MyPieceCoordinateValues),
  sum_list(MyPieceCoordinateValues, MyPieceCoordinateValueSum),

  other(Turn, OtherTurn),
  findall([X, Y], getSquare(X, Y, Board, [OtherTurn, _]), OtherPieceCoordinates), % combined value of enemy piece coordinates
  maplist(squareValue, OtherPieceCoordinates, OtherPieceCoordinateValues),
  sum_list(OtherPieceCoordinateValues, OtherPieceCoordinatesValueSum),

  Value is MyValue + MyPieceCoordinateValueSum - OtherValue - OtherPieceCoordinatesValueSum.

% recursive search for a valid trail, connecting (XFrom, YFrom) to (XTo, YTo) following a specific step size
isValidTrail(_, _, [XFrom, YFrom, XTo, YTo], XDirection, YDirection) :-
  XTo is XFrom + XDirection,
  YTo is YFrom + YDirection, !.
isValidTrail(Board, Turn, [XFrom, YFrom, XTo, YTo], XDirection, YDirection) :-
  NewX is XFrom + XDirection,
  NewY is YFrom + YDirection,
  getSquare(NewX, NewY, Board, empty),
  isValidTrail(Board, Turn, [NewX, NewY, XTo, YTo], XDirection, YDirection).

% KING MOVES
findMove(Board, Turn, [XFrom, YFrom, XTo, YTo]) :-
  nth1(XFrom, Board, Row),
  nth1(YFrom, Row, [Turn, king]),
  other(Turn, OtherTurn),
  (
    getSquare(XTo, YTo, Board, empty);
    getSquare(XTo, YTo, Board, [OtherTurn, _])
  ),
  (
    XTo is XFrom + 1, YTo = YFrom;
    XTo is XFrom - 1, YTo = YFrom;
    YTo is YFrom + 1, XTo = XFrom;
    YTo is YFrom - 1, XTo = XFrom
  ).

% QUEEN MOVES
findMove(Board, Turn, [XFrom, YFrom, XTo, YTo]) :-
  nth1(XFrom, Board, Row),
  nth1(YFrom, Row, [Turn, queen]),
  other(Turn, OtherTurn),
  (
    getSquare(XTo, YTo, Board, empty);
    getSquare(XTo, YTo, Board, [OtherTurn, _])
  ),
  (
    XTo < XFrom, YTo = YFrom, isValidTrail(Board, Turn, [XFrom, YFrom, XTo, YTo], -1, 0);
    XTo > XFrom, YTo = YFrom, isValidTrail(Board, Turn, [XFrom, YFrom, XTo, YTo], 1, 0);
    XTo = XFrom, YTo < YFrom, isValidTrail(Board, Turn, [XFrom, YFrom, XTo, YTo], 0, -1);
    XTo = XFrom, YTo > YFrom, isValidTrail(Board, Turn, [XFrom, YFrom, XTo, YTo], 0, 1);
    Dx is XTo - XFrom, Dx is YTo - YFrom, Dx < 0, isValidTrail(Board, Turn, [XFrom, YFrom, XTo, YTo], -1, -1);
    Dx is XTo - XFrom, Dx is YTo - YFrom, Dx > 0, isValidTrail(Board, Turn, [XFrom, YFrom, XTo, YTo], 1, 1);
    Dx is XTo - XFrom, Dx is YFrom - YTo, Dx < 0, isValidTrail(Board, Turn, [XFrom, YFrom, XTo, YTo], -1, 1);
    Dx is XTo - XFrom, Dx is YFrom - YTo, Dx > 0, isValidTrail(Board, Turn, [XFrom, YFrom, XTo, YTo], 1, -1)
  ).

% ROOK MOVES
findMove(Board, Turn, [XFrom, YFrom, XTo, YTo]) :-
  nth1(XFrom, Board, Row),
  nth1(YFrom, Row, [Turn, rook]),
  other(Turn, OtherTurn),
  (
    getSquare(XTo, YTo, Board, empty);
    getSquare(XTo, YTo, Board, [OtherTurn, _])
  ),
  (
    XTo < XFrom, YTo = YFrom, isValidTrail(Board, Turn, [XFrom, YFrom, XTo, YTo], -1, 0);
    XTo > XFrom, YTo = YFrom, isValidTrail(Board, Turn, [XFrom, YFrom, XTo, YTo], 1, 0);
    XTo = XFrom, YTo < YFrom, isValidTrail(Board, Turn, [XFrom, YFrom, XTo, YTo], 0, -1);
    XTo = XFrom, YTo > YFrom, isValidTrail(Board, Turn, [XFrom, YFrom, XTo, YTo], 0, 1)
  ).

% KNIGHT MOVES
findMove(Board, Turn, [XFrom, YFrom, XTo, YTo]) :-
  nth1(XFrom, Board, Row),
  nth1(YFrom, Row, [Turn, knight]),
  other(Turn, OtherTurn),
  (
    getSquare(XTo, YTo, Board, empty);
    getSquare(XTo, YTo, Board, [OtherTurn, _])
  ),
  (
    XTo is XFrom + 2, YTo is YFrom + 1; XTo is XFrom + 2, YTo is YFrom - 1;
    XTo is XFrom + 1, YTo is YFrom + 2; XTo is XFrom + 1, YTo is YFrom - 2;
    XTo is XFrom - 1, YTo is YFrom + 2; XTo is XFrom - 1, YTo is YFrom - 2;
    XTo is XFrom - 2, YTo is YFrom + 1; XTo is XFrom - 2, YTo is YFrom - 1
  ).

% BISHOP MOVES
findMove(Board, Turn, [XFrom, YFrom, XTo, YTo]) :-
  nth1(XFrom, Board, Row),
  nth1(YFrom, Row, [Turn, bishop]),
  other(Turn, OtherTurn),
  (
    getSquare(XTo, YTo, Board, empty);
    getSquare(XTo, YTo, Board, [OtherTurn, _])
  ),
  (
    Dx is XTo - XFrom, Dx is YTo - YFrom, Dx < 0, isValidTrail(Board, Turn, [XFrom, YFrom, XTo, YTo], -1, -1);
    Dx is XTo - XFrom, Dx is YTo - YFrom, Dx > 0, isValidTrail(Board, Turn, [XFrom, YFrom, XTo, YTo], 1, 1);
    Dx is XTo - XFrom, Dx is YFrom - YTo, Dx < 0, isValidTrail(Board, Turn, [XFrom, YFrom, XTo, YTo], -1, 1);
    Dx is XTo - XFrom, Dx is YFrom - YTo, Dx > 0, isValidTrail(Board, Turn, [XFrom, YFrom, XTo, YTo], 1, -1)
  ).

% PAWN MOVES (very complex and ad-hoc routine, ik)
findMove(Board, white, [XFrom, YFrom, XTo, YFrom]) :-
  nth1(XFrom, Board, Row),
  nth1(YFrom, Row, [white, pawn]),
  XTo is XFrom - 1,
  getSquare(XTo, YFrom, Board, empty).
findMove(Board, white, [XFrom, YFrom, XTo, YTo]) :-
  nth1(XFrom, Board, Row),
  nth1(YFrom, Row, [white, pawn]),
  XTo is XFrom - 1,
  (YTo is YFrom - 1; Yto is YFrom + 1),
  getSquare(XTo, Yto, Board, [black, _]).
findMove(Board, white, [7, YFrom, 5, YFrom]) :-
  nth1(7, Board, Row),
  nth1(YFrom, Row, [white, pawn]),
  getSquare(6, YFrom, Board, empty),
  getSquare(5, YFrom, Board, empty).
findMove(Board, black, [XFrom, YFrom, XTo, YFrom]) :-
  nth1(XFrom, Board, Row),
  nth1(YFrom, Row, [black, pawn]),
  XTo is XFrom + 1,
  getSquare(XTo, YFrom, Board, empty).
findMove(Board, black, [2, YFrom, 4, YFrom]) :-
  nth1(2, Board, Row),
  nth1(YFrom, Row, [black, pawn]),
  getSquare(3, YFrom, Board, empty),
  getSquare(4, YFrom, Board, empty).
findMove(Board, black, [XFrom, YFrom, XTo, YTo]) :-
  nth1(XFrom, Board, Row),
  nth1(YFrom, Row, [black, pawn]),
  XTo is XFrom + 1,
  (YTo is YFrom - 1; Yto is YFrom + 1),
  getSquare(XTo, Yto, Board, [white, _]).

% check for end of game (one king is dead)
isEnd(Board) :- \+ getSquare(_, _,Board, [white, king]), !.
isEnd(Board) :- \+ getSquare(_, _,Board, [black, king]).

getFirst([H | _], H).

% helper predicate of the search algorithm, with base cases
searchNode(Board, Turn, 0, Value, []) :- !, evaluate(Turn, Board, Value).
searchNode(Board, Turn, _, Value, []) :- isEnd(Board), !, evaluate(Turn, Board, Value).
searchNode(Board, Turn, Depth, BestValue, [Move | BestChildMoves]) :-
  findMove(Board, Turn, Move),
  makeMove(Board, Move, ChildBoard),
  other(Turn, ChildTurn),
  ChildDepth is Depth - 1,
  findall([ChildValue, ChildMoves], searchNode(ChildBoard, ChildTurn, ChildDepth, ChildValue, ChildMoves), ChildValueMoves), % recursion
  maplist(getFirst, ChildValueMoves, ChildValues),
  min_list(ChildValues, BestValue),
  nth1(Index, ChildValues, BestValue),
  nth1(Index, ChildValueMoves, [_, BestChildMoves]).

% for every move possible in the current situation choose the best one
search(Board, Turn, Depth, Moves) :-
  findall([ChildValue, ChildMoves], searchNode(Board, Turn, Depth, ChildValue, ChildMoves), ChildValueMoves),
  maplist(getFirst, ChildValueMoves, ChildValues),
  min_list(ChildValues, BestValue),
  nth1(Index, ChildValues, BestValue),
  nth1(Index, ChildValueMoves, [_, Moves]),
  nth1(1, Moves, Move),
  Move = [A, B, C, D],
  format("[~a, ~a, ~a, ~a]", [A, B, C, D]).