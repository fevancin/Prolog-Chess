"use strict";

const buttons = {
    newWhiteGame: document.getElementById("new-white-game"),
    newBlackGame: document.getElementById("new-black-game")
};
if (buttons.newWhiteGame === null || buttons.newBlackGame === null) throw new Error("Buttons not found");

const BOARD_DIM = 8;
const TYPES = ["king", "queen", "rook", "knight", "bishop", "pawn"];
const COLORS = ["white", "black"];
const SEARCH_DEPTH = 2;

const initialPieces = [
    {type: "rook", color: "white", x: 7, y: 7}, {type: "knight", color: "white", x: 6, y: 7},
    {type: "bishop", color: "white", x: 5, y: 7}, {type: "king", color: "white", x: 4, y: 7},
    {type: "queen", color: "white", x: 3, y: 7}, {type: "bishop", color: "white", x: 2, y: 7},
    {type: "knight", color: "white", x: 1, y: 7}, {type: "rook", color: "white", x: 0, y: 7},
    {type: "pawn", color: "white", x: 7, y: 6}, {type: "pawn", color: "white", x: 6, y: 6},
    {type: "pawn", color: "white", x: 5, y: 6}, {type: "pawn", color: "white", x: 4, y: 6},
    {type: "pawn", color: "white", x: 3, y: 6}, {type: "pawn", color: "white", x: 2, y: 6},
    {type: "pawn", color: "white", x: 1, y: 6}, {type: "pawn", color: "white", x: 0, y: 6},
    {type: "rook", color: "black", x: 7, y: 0}, {type: "knight", color: "black", x: 6, y: 0},
    {type: "bishop", color: "black", x: 5, y: 0}, {type: "king", color: "black", x: 4, y: 0},
    {type: "queen", color: "black", x: 3, y: 0}, {type: "bishop", color: "black", x: 2, y: 0},
    {type: "knight", color: "black", x: 1, y: 0}, {type: "rook", color: "black", x: 0, y: 0},
    {type: "pawn", color: "black", x: 7, y: 1}, {type: "pawn", color: "black", x: 6, y: 1},
    {type: "pawn", color: "black", x: 5, y: 1}, {type: "pawn", color: "black", x: 4, y: 1},
    {type: "pawn", color: "black", x: 3, y: 1}, {type: "pawn", color: "black", x: 2, y: 1},
    {type: "pawn", color: "black", x: 1, y: 1}, {type: "pawn", color: "black", x: 0, y: 1}
];

// creating a dictionary of images, cloning is faster than loading multiple times
const images = {};
for (const color of COLORS) {
    images[color] = {}
    for (const type of TYPES) {
        const image = new Image();
        image.src = "svg/" + color + type + ".svg";
        image.alt = "svg of " + color + " " + type;
        images[color][type] = image;
    }
}

// creating the global board variable, with element and piece references
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

let turn = "white";

let lastMove = null;
let selectedSquare = null;

// reset the board to the initial state
function placeInitialPieces() {
    for (let i = 0; i < BOARD_DIM; i++) {
        for (let j = 0; j < BOARD_DIM; j++) {
            const square = board[i][j];
            if (square.piece !== null) {
                square.td.firstChild.remove();
                square.piece = null;
            }
        }
    }
    for (const piece of initialPieces) {
        const square = board[piece.y][piece.x];
        square.piece = {type: piece.type, color: piece.color};
        square.td.appendChild(images[piece.color][piece.type].cloneNode());
    }
    if (lastMove !== null) {
        board[lastMove.from.x][lastMove.from.y].td.classList.remove("lastmove");
        board[lastMove.to.x][lastMove.to.y].td.classList.remove("lastmove");
        lastMove = null;
    }
    if (selectedSquare !== null) {
        board[selectedSquare.x][selectedSquare.y].td.classList.remove("selected");
        selectedSquare = null;
    }
    turn = "white";
}

function setLastMove(xFrom, yFrom, xTo, yTo) {
    if (lastMove !== null) {
        board[lastMove.from.x][lastMove.from.y].td.classList.remove("lastmove");
        board[lastMove.to.x][lastMove.to.y].td.classList.remove("lastmove");
    }
    lastMove = {
        from: {x: xFrom, y: yFrom},
        to: {x: xTo, y: yTo}
    };
    board[lastMove.from.x][lastMove.from.y].td.classList.add("lastmove");
    board[lastMove.to.x][lastMove.to.y].td.classList.add("lastmove");
}

function askComputer() {
    const ws = new WebSocket("ws://127.0.0.1:8080");
    ws.onopen = () => ws.send(buildPrologRequest());
    ws.onerror = () => console.error("An error has occurred");
    ws.onmessage = (event) => {
        const xFrom = +event.data[1] - 1;
        const yFrom = +event.data[4] - 1;
        const xTo = +event.data[7] - 1;
        const yTo = +event.data[10] - 1;
        move(xFrom, yFrom, xTo, yTo);
        setLastMove(xFrom, yFrom, xTo, yTo);
        ws.close();
    };
}

function click(x, y) {
    if (selectedSquare === null) {
        board[x][y].td.classList.add("selected");
        selectedSquare = {x: x, y: y};
        return;
    }
    board[selectedSquare.x][selectedSquare.y].td.classList.remove("selected");
    if (selectedSquare.x === x && selectedSquare.y === y) {
        selectedSquare = null;
        return;
    }
    if (selectedSquare.piece !== null && canMove(selectedSquare.x, selectedSquare.y, x, y)) {
        move(selectedSquare.x, selectedSquare.y, x, y);
        setLastMove(selectedSquare.x, selectedSquare.y, x, y);
        selectedSquare = null;
        if (!isGameEnded()) askComputer();
        return;
    }
    board[x][y].td.classList.add("selected");
    selectedSquare = {x: x, y: y};
}

const handlers = [];
for (let i = 0; i < BOARD_DIM; i++) {
    const row = [];
    for (let j = 0; j < BOARD_DIM; j++) {
        const handler = () => {
            click(i, j);
        };
        row.push(handler);
        board[i][j].td.addEventListener("click", handler);
    }
    handlers.push(row);
}

function isGameEnded() {
    let isWhiteKing = false;
    let isBlackKing = false;
    for (let i = 0; i < BOARD_DIM; i++) {
        for (let j = 0; j < BOARD_DIM; j++) {
            const square = board[i][j].piece;
            if (square !== null && square.type === "king") {
                if (square.color === "white") isWhiteKing = true;
                if (square.color === "black") isBlackKing = true;
            }
        }
    }
    return (!isBlackKing) || (!isWhiteKing);
}

const moveVectors = {
    king: [{x: -1, y: -1, t: 1}, {x: -1, y: 0, t: 1}, {x: -1, y: 1, t: 1}, {x: 0, y: -1, t: 1}, {x: 0, y: 1, t: 1}, {x: 1, y: -1, t: 1}, {x: 1, y: 0, t: 1}, {x: 1, y: 1, t: 1}],
    queen: [{x: -1, y: -1, t: 8}, {x: -1, y: 0, t: 8}, {x: -1, y: 1, t: 8}, {x: 0, y: -1, t: 8}, {x: 0, y: 1, t: 8}, {x: 1, y: -1, t: 8}, {x: 1, y: 0, t: 8}, {x: 1, y: 1, t: 8}],
    rook: [{x: -1, y: 0, t: 8}, {x: 0, y: -1, t: 8}, {x: 0, y: 1, t: 8}, {x: 1, y: 0, t: 8}],
    knight: [{x: -2, y: -1, t: 1}, {x: -2, y: 1, t: 1}, {x: -1, y: -2, t: 1}, {x: -1, y: 2, t: 1}, {x: 1, y: -2, t: 1}, {x: 1, y: 2, t: 1}, {x: 2, y: -1, t: 1}, {x: 2, y: 1, t: 1}],
    bishop: [{x: -1, y: -1, t: 8}, {x: -1, y: 1, t: 8}, {x: 1, y: -1, t: 8}, {x: 1, y: 1, t: 8}]
};

// returns true if (xFrom, yFrom) to (xTo, yTo) is a legal move
function canMove(xFrom, yFrom, xTo, yTo) {
    if (isGameEnded()) return false;
    const squareFrom = board[xFrom][yFrom];
    const squareTo = board[xTo][yTo];
    if (squareFrom.piece === null) return false; // TODO search for kings.........................................................
    if (squareFrom.piece.color !== turn) return false;
    if (xFrom === xTo && yFrom === yTo) return false;
    if (squareFrom.piece.type === "pawn") {
        const direction = (turn === "white") ? -1 : 1;
        if (xFrom + direction === xTo && yFrom === yTo) { // pawn single advancement
            if (squareTo.piece === null) return true;
            return false;
        }
        if (xFrom + 2 * direction === xTo && yFrom === yTo) { // pawn double initial advancement
            if ((xFrom === 6 && turn === "white") || (xFrom === 1 && turn === "black")) {
                if (squareTo.piece === null && board[xFrom + direction][yFrom].piece === null) return true;
            }
            return false;
        }
        if (xFrom + direction === xTo && (yFrom === yTo - 1 || yFrom === yTo + 1)) { // pawn eat
            if (squareTo.piece !== null && squareTo.piece.color !== turn) return true;
            return false;
        }
        return false;
    }
    const moveVector = moveVectors[squareFrom.piece.type];
    for (const direction of moveVector) {
        let x = xFrom;
        let y = yFrom;
        for (let t = 0; t < direction.t; t++) {
            x += direction.x;
            y += direction.y;
            if (x < 0 || x >= BOARD_DIM || y < 0 || y >= BOARD_DIM) break;
            if (x === xTo && y === yTo) {
                if (squareTo.piece === null || squareTo.piece.color !== squareFrom.piece.color) return true;
                else return false;
            }
            if (board[x][y].piece !== null) break;
        }
    }
    return false;
}

// move the piece at (xFrom, yFrom) to (xTo, yTo)
function move(xFrom, yFrom, xTo, yTo) {
    const squareFrom = board[xFrom][yFrom];
    const squareTo = board[xTo][yTo];
    if (squareTo.piece !== null) squareTo.td.firstChild.remove();
    squareTo.td.appendChild(squareFrom.td.firstChild);
    squareTo.piece = squareFrom.piece;
    squareFrom.piece = null;
    turn = (turn === "white") ? "black" : "white";
    if (squareTo.piece.type === "pawn" &&
        ((xTo === 0 && squareTo.piece.color === "white") ||
        ((xTo === BOARD_DIM - 1 && squareTo.piece.color === "black")))
    ) {
        squareTo.piece.type = "queen"; // promotion
        squareTo.td.firstChild.remove();
        squareTo.td.appendChild(images[squareTo.piece.color]["queen"].cloneNode());
    }
}

function boardToPrologString() {
    let string = "[";
    for (let i = 0; i < BOARD_DIM; i++) {
        string += "[";
        for (let j = 0; j < BOARD_DIM; j++) {
            const piece = board[i][j].piece;
            if (piece === null) string += "empty";
            else string += "[" + piece.color + "," + piece.type + "]";
            if (j + 1 < BOARD_DIM) string += ",";
        }
        string += "]";
        if (i + 1 < BOARD_DIM) string += ",";
    }
    string += "]";
    return string;
}

function buildPrologRequest() {
    return "search(" +
        boardToPrologString() + ", " +
        turn + ", " +
        SEARCH_DEPTH + ", Moves).";
}

buttons.newWhiteGame.addEventListener("click", () => {
    placeInitialPieces();
});

buttons.newBlackGame.addEventListener("click", () => {
    placeInitialPieces();
    askComputer(); // computer make first move
});

placeInitialPieces();