"use strict";

const div = document.getElementById("chessboard");
if (div === null) throw new Error("Chessboard element not found");

const BOARD_DIM = 8;
const TYPES = ["king", "queen", "rook", "knight", "bishop", "pawn"];
const COLORS = ["white", "black"];

const board = [];
for (let i = 0; i < BOARD_DIM; i++) {
    const row = [];
    for (let j = 0; j < BOARD_DIM; j++) {
        const td = document.getElementById("s" + i + j);
        if (td === null) throw new Error("<td> element (" + i + ", " + j + ") not found");
        row.push({
            td: td,
            piece: null
        });
    }
    board.push(row);
}

const svgs = {};
for (const color of COLORS) {
    svgs[color] = {}
    for (const type of TYPES) {
        const image = new Image();
        image.src = "svg/" + color + type + ".svg";
        image.alt = "svg of " + color + " " + type;
        svgs[color][type] = image;
    }
}

const initialConfiguration = [
    {type: "rook", color: "white", x: 7, y: 7},
    {type: "knight", color: "white", x: 6, y: 7},
    {type: "bishop", color: "white", x: 5, y: 7},
    {type: "queen", color: "white", x: 4, y: 7},
    {type: "king", color: "white", x: 3, y: 7},
    {type: "bishop", color: "white", x: 2, y: 7},
    {type: "knight", color: "white", x: 1, y: 7},
    {type: "rook", color: "white", x: 0, y: 7},
    {type: "pawn", color: "white", x: 7, y: 6},
    {type: "pawn", color: "white", x: 6, y: 6},
    {type: "pawn", color: "white", x: 5, y: 6},
    {type: "pawn", color: "white", x: 4, y: 6},
    {type: "pawn", color: "white", x: 3, y: 6},
    {type: "pawn", color: "white", x: 2, y: 6},
    {type: "pawn", color: "white", x: 1, y: 6},
    {type: "pawn", color: "white", x: 0, y: 6},
    {type: "rook", color: "black", x: 7, y: 0},
    {type: "knight", color: "black", x: 6, y: 0},
    {type: "bishop", color: "black", x: 5, y: 0},
    {type: "queen", color: "black", x: 4, y: 0},
    {type: "king", color: "black", x: 3, y: 0},
    {type: "bishop", color: "black", x: 2, y: 0},
    {type: "knight", color: "black", x: 1, y: 0},
    {type: "rook", color: "black", x: 0, y: 0},
    {type: "pawn", color: "black", x: 7, y: 1},
    {type: "pawn", color: "black", x: 6, y: 1},
    {type: "pawn", color: "black", x: 5, y: 1},
    {type: "pawn", color: "black", x: 4, y: 1},
    {type: "pawn", color: "black", x: 3, y: 1},
    {type: "pawn", color: "black", x: 2, y: 1},
    {type: "pawn", color: "black", x: 1, y: 1},
    {type: "pawn", color: "black", x: 0, y: 1}
];

for (const piece of initialConfiguration) {
    const square = board[piece.y][piece.x];
    const image = square.td.firstElementChild;
    if (image !== null) image.remove();
    square.piece = {type: piece.type, color: piece.color};
    square.td.appendChild(svgs[piece.color][piece.type].cloneNode());
}