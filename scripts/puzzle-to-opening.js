// This invocation created the current puzzle_openings.epd
// node puzzle-to-opening.js lichess_db_puzzle.csv 14 > puzzle_openings.epd

const fs = require('fs');
const readline = require('readline');
const { Chess } = require('chess.js');

function countTotalLetters(str) {
    // Purpose: count number of pieces on the board in FEN.
    const lettersToCount = ['K', 'k', 'Q', 'q', 'R', 'r', 'B', 'b', 'N', 'n', 'P', 'p'];
    let totalCount = 0;
    for (let char of str) {
        if (lettersToCount.includes(char)) {
            totalCount++;
        }
    }
    return totalCount;
}

// Read the CSV file name from command line arguments
const csvFileName = process.argv[2];
const number_of_pieces = parseInt(process.argv[3]);

// Create a readable stream from the CSV file
const fileStream = fs.createReadStream(csvFileName, 'utf8');

// Initialize a CSV parser (you can use a library like 'csv-parser' for more robust parsing)
const rl = readline.createInterface({
  input: fileStream,
  crlfDelay: Infinity, // Detect line breaks correctly
});

let isFirstLine = true; // Flag to skip the first line

// Process each row (ignoring the header)
rl.on('line', (line) => {

  if (isFirstLine) {
    isFirstLine = false;
    return; // Skip the header
  }
    
  const [_, fen, moves] = line.split(',');

  // Initialize a chess board with the provided FEN
  const chess = new Chess(fen);

  // Split the moves string and apply the first move
  const moveList = moves.split(' ');
  if (moveList.length > 0) {
    const firstMove = moveList[0];
    chess.move(firstMove);
  }

// // Read CSV data from the file (replace with error handling as needed)
// const csvData = fs.readFileSync(csvFileName, 'utf8')
//   .split('\n')
//   .map((line) => line.split(','));

// // Process each row (ignoring the header)
// for (let i = 1; i < csvData.length-1; i++) {
//   const [_, fen, moves] = csvData[i]; // Destructure the row

//   // Initialize a chess board with the provided FEN
//   const chess = new Chess(fen);

//   // Split the moves string and apply the first move
//   const moveList = moves.split(' ');
//   if (moveList.length > 0) {
//     const firstMove = moveList[0];
//     chess.move(firstMove);
//   }

    // Print the resulting FEN, if it has at most the desired number of pieces
    if (countTotalLetters(chess.fen().split(" ")[0]) <= number_of_pieces){
	console.log(`[FEN "${chess.fen()}"]`);
    }
})

