#!/bin/bash

# Create project directories
echo "Creating project structure..."
mkdir -p vsws/{handler,utils,templates/{images,audio}}

# Navigate to project directory
cd vsws

# Create go.mod file
echo "Initializing Go module..."
cat > go.mod << EOL
module github.com/yourusername/vsws

go 1.21
EOL

# Create main.go
echo "Creating main.go..."
cat > main.go << 'EOL'
// main.go
package main

import (
	"fmt"
	"log"
	"net"
	"os"
	"strings"
	"time"
	"path/filepath"
	
	"github.com/yourusername/vsws/handler"
	"github.com/yourusername/vsws/utils"
)

const (
	HOST = "127.0.0.1"
	PORT = "9999"
	BUFFER_SIZE = 1024
)

func main() {
	// Create TCP listener
	listener, err := net.Listen("tcp", HOST+":"+PORT)
	if err != nil {
		log.Fatal("Error creating listener:", err)
	}
	defer listener.Close()

	fmt.Printf("Very Simple Web Server running on %s:%s\n", HOST, PORT)
	fmt.Println("Press Ctrl+C to stop the server")

	// Main server loop
	for {
		conn, err := listener.Accept()
		if err != nil {
			log.Println("Error accepting connection:", err)
			continue
		}

		// Handle connection in a goroutine
		go handleConnection(conn)
	}
}

func handleConnection(conn net.Conn) {
	defer conn.Close()

	// Set timeout for reading
	conn.SetReadDeadline(time.Now().Add(30 * time.Second))

	// Buffer to receive data
	buffer := make([]byte, BUFFER_SIZE)
	n, err := conn.Read(buffer)
	if err != nil {
		log.Println("Error reading from connection:", err)
		return
	}

	// Parse request
	request := string(buffer[:n])
	fmt.Printf("Received request:\n%s\n", request)

	// Use handler package to parse request
	httpRequest, err := handler.ParseRequest(request)
	if err != nil {
		log.Println("Error parsing request:", err)
		sendError(conn, 400, "Bad Request")
		return
	}

	// Check if it's a GET request
	if httpRequest.Method != "GET" {
		sendError(conn, 405, "Method Not Allowed")
		return
	}

	// Get the requested path
	path := httpRequest.Path
	if path == "/" {
		path = "/index.html"
	}

	// Sanitize path to prevent directory traversal
	cleanPath := utils.SanitizePath(strings.TrimPrefix(path, "/"))
	if cleanPath == "" {
		sendError(conn, 400, "Bad Request")
		return
	}

	filePath := filepath.Join("templates", cleanPath)

	// Determine content type based on file extension
	contentType := utils.GetContentType(filePath)

	// Read the file
	content, err := os.ReadFile(filePath)
	if err != nil {
		sendError(conn, 404, "Not Found")
		return
	}

	// Send response using handler helper
	response := handler.CreateResponseHeader(200, "OK", contentType, len(content))
	conn.Write([]byte(response))
	conn.Write(content)
}

func sendError(conn net.Conn, statusCode int, phrase string) {
	errorContent := fmt.Sprintf("<html><body><h1>%d %s</h1></body></html>", statusCode, phrase)
	response := fmt.Sprintf("HTTP/1.1 %d %s\r\n"+
		"Content-Length: %d\r\n"+
		"Content-Type: text/html\r\n"+
		"Connection: close\r\n"+
		"\r\n"+
		"%s", statusCode, phrase, len(errorContent), errorContent)
	
	conn.Write([]byte(response))
}

// This function is now in utils package
EOL

# Create handler/http_handler.go
echo "Creating handler/http_handler.go..."
cat > handler/http_handler.go << 'EOL'
// handler/http_handler.go
package handler

import (
	"fmt"
	"strings"
)

type HTTPRequest struct {
	Method  string
	Path    string
	Version string
	Headers map[string]string
}

func ParseRequest(request string) (*HTTPRequest, error) {
	req := &HTTPRequest{
		Headers: make(map[string]string),
	}

	lines := strings.Split(request, "\r\n")
	if len(lines) < 1 {
		return nil, fmt.Errorf("empty request")
	}

	// Parse request line
	parts := strings.Split(lines[0], " ")
	if len(parts) != 3 {
		return nil, fmt.Errorf("invalid request line")
	}

	req.Method = parts[0]
	req.Path = parts[1]
	req.Version = parts[2]

	// Parse headers
	for i := 1; i < len(lines); i++ {
		if lines[i] == "" {
			break
		}
		
		headerParts := strings.SplitN(lines[i], ": ", 2)
		if len(headerParts) == 2 {
			req.Headers[headerParts[0]] = headerParts[1]
		}
	}

	return req, nil
}

func CreateResponseHeader(statusCode int, phrase string, contentType string, contentLength int) string {
	return fmt.Sprintf("HTTP/1.1 %d %s\r\n"+
		"Server: Very Simple Web Server\r\n"+
		"Content-Length: %d\r\n"+
		"Content-Type: %s\r\n"+
		"Connection: close\r\n"+
		"\r\n", statusCode, phrase, contentLength, contentType)
}
EOL

# Create utils/file_utils.go
echo "Creating utils/file_utils.go..."
cat > utils/file_utils.go << 'EOL'
// utils/file_utils.go
package utils

import (
	"path/filepath"
	"strings"
)

func GetContentType(path string) string {
	ext := strings.ToLower(filepath.Ext(path))
	switch ext {
	case ".html", ".htm":
		return "text/html"
	case ".jpg", ".jpeg":
		return "image/jpeg"
	case ".png":
		return "image/png"
	case ".gif":
		return "image/gif"
	case ".mp3":
		return "audio/mpeg"
	case ".wav":
		return "audio/wav"
	case ".midi", ".mid":
		return "audio/midi"
	case ".css":
		return "text/css"
	case ".js":
		return "application/javascript"
	case ".txt":
		return "text/plain"
	default:
		return "application/octet-stream"
	}
}

func SanitizePath(path string) string {
	// Prevent directory traversal attacks
	cleanPath := filepath.Clean(path)
	if strings.HasPrefix(cleanPath, "..") {
		return ""
	}
	return cleanPath
}
EOL

# Create templates/index.html
echo "Creating templates/index.html..."
cat > templates/index.html << 'EOL'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Very Simple Web Server</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            line-height: 1.6;
            margin: 0;
            padding: 20px;
            background-color: #f4f4f4;
        }
        .container {
            max-width: 800px;
            margin: 0 auto;
            background: white;
            padding: 20px;
            border-radius: 5px;
            box-shadow: 0 2px 5px rgba(0,0,0,0.1);
        }
        h1 {
            color: #333;
            text-align: center;
        }
        .content {
            margin-top: 20px;
        }
        .media {
            margin: 20px 0;
            padding: 10px;
            border: 1px solid #ddd;
            border-radius: 5px;
        }
        img {
            max-width: 100%;
            height: auto;
        }
        audio {
            width: 100%;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>Welcome to Very Simple Web Server</h1>
        
        <div class="content">
            <p>This is a simple web server built with Go using TCP sockets.</p>
            
            <div class="media">
                <h2>Image Example</h2>
                <img src="/images/sample.jpg" alt="Sample Image">
            </div>
            
            <div class="media">
                <h2>Audio Example</h2>
                <audio controls>
                    <source src="/audio/sample.mp3" type="audio/mpeg">
                    Your browser does not support the audio element.
                </audio>
            </div>
            
            <p>Test links:</p>
            <ul>
                <li><a href="/images/sample.jpg">Direct link to image</a></li>
                <li><a href="/audio/sample.mp3">Direct link to audio</a></li>
                <li><a href="/nonexistent.html">404 Error example</a></li>
            </ul>
        </div>
    </div>
</body>
</html>
EOL

# Create error.html template
echo "Creating templates/error.html..."
cat > templates/error.html << 'EOL'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Error - Very Simple Web Server</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            line-height: 1.6;
            margin: 0;
            padding: 20px;
            background-color: #f8d7da;
        }
        .container {
            max-width: 800px;
            margin: 0 auto;
            background: white;
            padding: 20px;
            border-radius: 5px;
            box-shadow: 0 2px 5px rgba(0,0,0,0.1);
            border: 1px solid #f5c6cb;
        }
        h1 {
            color: #721c24;
            text-align: center;
        }
        .error-code {
            font-size: 72px;
            text-align: center;
            color: #721c24;
            margin: 20px 0;
        }
        .error-message {
            text-align: center;
            font-size: 24px;
            margin-bottom: 20px;
        }
        .home-link {
            display: block;
            text-align: center;
            margin-top: 30px;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>Error</h1>
        <div class="error-code">{{ERROR_CODE}}</div>
        <div class="error-message">{{ERROR_MESSAGE}}</div>
        <p>The server could not process your request at this time.</p>
        <a href="/" class="home-link">Return to Home</a>
    </div>
</body>
</html>
EOL

# Create README.md
echo "Creating README.md..."
cat > README.md << 'EOL'
# Very Simple Web Server (VSWS)

A simple web server implementation using TCP sockets in Go. This server can handle basic HTTP GET requests and serve static files including HTML, images, and audio files.

## Features

- Basic HTTP GET request handling
- Static file serving (HTML, images, audio)
- Custom error pages (404, 400, 405)
- Content-type detection
- Path sanitization to prevent directory traversal attacks

## Project Structure

```
vsws/
├── main.go                 # Main server program
├── handler/               
│   └── http_handler.go     # HTTP request handling logic
├── utils/
│   └── file_utils.go       # Utility functions for file operations
├── templates/              # HTML and static files
│   ├── index.html         # Main HTML file
│   ├── error.html         # Error page template
│   ├── images/
│   │   └── sample.jpg     # Sample image file
│   └── audio/
│       └── sample.mp3     # Sample audio file
├── go.mod                 # Go module file
└── README.md              # This file
```

## Installation

1. Clone or create the project directory:
```bash
mkdir vsws
cd vsws
```

2. Create all the necessary files as shown in the project structure above.

3. Place your static files (images, audio) in the appropriate folders:
   - Images go in `templates/images/`
   - Audio files go in `templates/audio/`

## Running the Server

1. Navigate to the project directory:
```bash
cd vsws
```

2. Run the server:
```bash
go run main.go
```

The server will start on `127.0.0.1:9999`

3. Open a web browser and navigate to:
```
http://127.0.0.1:9999/index.html
```

## Testing

To test the server functionality:

1. Access the main page: `http://127.0.0.1:9999/index.html`
2. Test image loading: `http://127.0.0.1:9999/images/sample.jpg`
3. Test audio loading: `http://127.0.0.1:9999/audio/sample.mp3`
4. Test 404 error: `http://127.0.0.1:9999/nonexistent.html`

## Supported File Types

- HTML files: `.html`, `.htm`
- Images: `.jpg`, `.jpeg`, `.png`, `.gif`
- Audio: `.mp3`, `.wav`, `.midi`, `.mid`
- Others: `.css`, `.js`, `.txt`

## Error Handling

The server provides appropriate error responses:
- 400 Bad Request: For malformed HTTP requests
- 404 Not Found: For non-existent resources
- 405 Method Not Allowed: For non-GET methods

## License

MIT License
EOL

# Create placeholder image and audio files
echo "Creating placeholder image and audio files..."
echo "You need to replace these files with actual image and audio files."
touch templates/images/sample.jpg
touch templates/audio/sample.mp3

echo "Setup completed successfully!"
echo "To run the server, execute: go run main.go"
echo "Then visit http://127.0.0.1:9999 in your browser"