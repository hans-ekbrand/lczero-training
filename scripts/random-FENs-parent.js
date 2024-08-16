// Example usage: node generateFENs.random-FENs-parent 14 1000000 false

const numberOfPieces = parseInt(process.argv[2]); // Read the first command-line argument
const numberOfFENsToGenerate = parseInt(process.argv[3]); // Read the second command-line argument
const create_pgn = process.argv[4]; // if true then make a pgn, otherwise make a text files with one FEN per line.

const os = require('os');
const numCores = os.cpus().length;

function divideIntoChunks(n, k) {
    // divide n into k chunks
    const chunkSize = Math.floor(n / k); // Initial chunk size
    const remainder = n % k; // Remainder after division
    const chunks = [];
    let currentChunkSize = chunkSize;
    for (let i = 0; i < k; i++) {
        if ((i == k - 1) && (remainder > 0)) {
	    // last chunk, if remainder is positive, add it now
            currentChunkSize += remainder;
        }
        chunks.push(currentChunkSize);
    }
    return chunks;
}

// const generatedFENs = Array.from({ length: numberOfFENsToGenerate }, () => generateRandomFEN(numberOfPieces));

// Parallelized version
const { fork } = require('child_process');
const generatedFENs = []; // Initialize an empty array to store results

// Create child processes
const workers = [];
const chunks = divideIntoChunks(numberOfFENsToGenerate, numCores);

for (let i = 0; i < numCores; i++) {
    const worker = fork('random-FENs-child_processes.js', [numberOfPieces, chunks[i], create_pgn]);

    // Listen for messages from workers
    worker.on('message', result => {
        generatedFENs.push(result); // Collect processed FENs
    });

    workers.push(worker);
}
// When all workers are done, handle the combined results
Promise.all(workers.map(worker => new Promise(resolve => {
    worker.on('exit', () => resolve());
}))).then(() => {
    // Save the FENs to a file (e.g., 5-men-fens.pgn)
    const fs = require('fs');
    if (create_pgn  === 'true') {    
	fs.writeFileSync(`${numberOfPieces}-men-fens.pgn`, generatedFENs.join('\n') + "\n");
    } else {
	fs.writeFileSync(`${numberOfPieces}-men-fens.pgn`, generatedFENs.join('\n'));	
    }
});

