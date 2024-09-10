// Import the required modules
const express = require('express');
const path = require('path');

// Create an instance of express
const app = express();

// Define the port to run the server on
const PORT = 3000;

// Serve static files (CSS)
app.use(express.static(path.join(__dirname, 'public')));

// Define the root route to send an HTML file
app.get('/', (req, res) => {
    res.sendFile(path.join(__dirname, 'views', 'index.html'));
});

// Start the server and listen on the specified port
app.listen(PORT, '0.0.0.0',() => {
    console.log(`Server is running on http://localhost:${PORT}`);
});

