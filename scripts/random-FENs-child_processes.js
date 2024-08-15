// Example usage: random-FENs-child_processes.js 14 100

const { Chess } = require('chess.js');

// Generate a random integer between min (inclusive) and max (inclusive)
function getRandomInt(min, max) {
  return Math.floor(Math.random() * (max - min + 1)) + min;
}

function getRandomSquare(range) {
    return String.fromCharCode(97 + Math.floor(Math.random() * 8)) + getRandomInt(range[0], range[1]);
}

function getRandomPiece() {
    const pieces = ['q', 'r', 'b', 'n', 'p'];
    return pieces[Math.floor(Math.random() * pieces.length)];
}

function getRandomColor() {
    return Math.random() < 0.5 ? 'w' : 'b';
}

function generateRandomFEN(numberOfPieces, create_pgn) {
    let completedSuccessfully = false;
    let fen;

    while (!completedSuccessfully) {
        const board = new Chess()
	board.clear()
        const occupiedSquares = [];

        // Place the two kings at random locations
        const blackKingSquare = getRandomSquare([1, 8]);
        board.put({type: 'k', color: 'b'}, blackKingSquare);
        occupiedSquares.push(blackKingSquare);

	let conditionMet = false;
	while (!conditionMet) {
	    const whiteKingSquare = getRandomSquare([1, 8]);
	    if (whiteKingSquare != blackKingSquare) {
		board.put({type: 'k', color: 'w'}, whiteKingSquare);
		occupiedSquares.push(whiteKingSquare);
		conditionMet = true;
	    }
	}

        let i = numberOfPieces - 2; // Subtract 2 for the two kings already placed
        while (i > 0) {
            const pieceType = getRandomPiece();
            const validRange = pieceType === 'p' ? [2, 7] : [1, 8];
            const square = getRandomSquare(validRange);

            if (!occupiedSquares.includes(square)) {
                board.put({ type: pieceType, color: getRandomColor()}, square);
                occupiedSquares.push(square);
                i--;
            }
        }

        // Validate if the position is legal
        const blackToMoveBoard = new Chess(board.fen().replace('w', 'b'));
        completedSuccessfully = !board.inCheck() && !board.isCheckmate() && !board.isStalemate() &&
            !blackToMoveBoard.inCheck();

        if (completedSuccessfully) {
            fen = board.fen();
        }
    }

    if (create_pgn  === 'true') {
	return `[FEN "${fen}"]\n*\n`;
    } else {
	return fen;
    }
}

const numberOfPieces = process.argv[2];
const numberOfFENsToGenerate = process.argv[3];
const create_pgn = process.argv[4];

const generatedFENs = Array.from({ length: numberOfFENsToGenerate }, () => generateRandomFEN(numberOfPieces, create_pgn));

process.send(generatedFENs.join("\n"));




