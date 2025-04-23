// main.go - Very Simple Web Server (VSWS)
package main

import (
	"fmt"
	"log"
	"net"
	"os"
	"path/filepath"
	"strings"
	"time"
	"html/template"
	"bytes"
	
	"github.com/ThuanTheBadLuckCoder/netcentric-lab05/handler"
	"github.com/ThuanTheBadLuckCoder/netcentric-lab05/utils"

	// github.com/ThuanTheBadLuckCoder/netcentric-lab05
)

const (
	HOST = "127.0.0.1"  // Localhost
	PORT = "9999"       // Port number for the web server
	BUFFER_SIZE = 1024  // Buffer size for receiving HTTP requests (Exercise 1)
)

// Main function - entry point of the program
func main() {
	// Create TCP listener on specified host and port
	listener, err := net.Listen("tcp", HOST+":"+PORT)
	if err != nil {
		log.Fatal("Error creating TCP listener:", err)
	}
	defer listener.Close()

	// Display server information
	fmt.Printf("Very Simple Web Server (VSWS) running on http://%s:%s\n", HOST, PORT)
	fmt.Println("Press Ctrl+C to stop the server")

	// Main server loop - continuously accept connections
	for {
		// Accept incoming connection
		conn, err := listener.Accept()
		if err != nil {
			log.Println("Error accepting connection:", err)
			continue
		}

		// Handle connection in a goroutine (concurrent handling)
		go handleConnection(conn)
	}
}

// handleConnection processes a single client connection
func handleConnection(conn net.Conn) {
	defer conn.Close()

	// Set timeout for reading to prevent hanging connections
	conn.SetReadDeadline(time.Now().Add(30 * time.Second))

	// Exercise 1: Create buffer with appropriate size (1024 bytes)
	buffer := make([]byte, BUFFER_SIZE)
	n, err := conn.Read(buffer)
	if err != nil {
		log.Println("Error reading from connection:", err)
		return
	}

	// Parse HTTP request string
	request := string(buffer[:n])
	fmt.Printf("\n--- Received HTTP Request ---\n%s\n---------------------------\n", request)

	// Use handler package to parse request
	httpRequest, err := handler.ParseRequest(request)
	if err != nil {
		log.Println("Error parsing request:", err)
		// Exercise 5: Handle error - Bad Request
		sendErrorPage(conn, 400, "Bad Request")
		return
	}

	// Check if it's a GET request
	if httpRequest.Method != "GET" {
		// Exercise 5: Handle error - Method Not Allowed
		sendErrorPage(conn, 405, "Method Not Allowed")
		return
	}

	// Get the requested path (URL from Exercise 1)
	path := httpRequest.Path
	if path == "/" {
		path = "/index.html"
	}

	// Remove leading slash and sanitize path
	cleanPath := utils.SanitizePath(strings.TrimPrefix(path, "/"))
	if cleanPath == "" {
		sendErrorPage(conn, 400, "Bad Request")
		return
	}

	// Form the complete file path
	filePath := filepath.Join("templates", cleanPath)

	// Exercise 4: Determine content type based on file extension
	// This supports various file types including images and audio
	contentType := utils.GetContentType(filePath)

	// Check if file exists
	fileInfo, err := os.Stat(filePath)
	if err != nil || fileInfo.IsDir() {
		// Exercise 5: Handle error - Not Found
		fmt.Printf("File not found: %s\n", filePath)
		sendErrorPage(conn, 404, "Not Found")
		return
	}

	// Exercise 3: Read the requested file (index.html or other files)
	content, err := os.ReadFile(filePath)
	if err != nil {
		// Exercise 5: Handle error - Internal Server Error
		sendErrorPage(conn, 500, "Internal Server Error")
		return
	}

	// Create and send HTTP response
	// Exercise 2 & 3: Send HTTP response with appropriate content
	response := handler.CreateResponseHeader(200, "OK", contentType, len(content))
	
	// Write HTTP response header
	_, err = conn.Write([]byte(response))
	if err != nil {
		log.Println("Error writing response header:", err)
		return
	}
	
	// Write HTTP response body (file content)
	_, err = conn.Write(content)
	if err != nil {
		log.Println("Error writing response body:", err)
		return
	}
	
	fmt.Printf("Successfully served: %s (%s)\n", filePath, contentType)
}

// sendErrorPage generates and sends an error page
// This is for Exercise 5: Improve server to deal with unavailable resources
func sendErrorPage(conn net.Conn, statusCode int, phrase string) {
	// Try to use error template if exists
	errorTemplate, err := template.ParseFiles("templates/error.html")
	
	var content []byte
	
	if err == nil {
		// Template exists, use it
		data := struct {
			ErrorCode    int
			ErrorMessage string
		}{
			ErrorCode:    statusCode,
			ErrorMessage: phrase,
		}
		
		// Render template to buffer
		buf := new(bytes.Buffer)
		if err := errorTemplate.Execute(buf, data); err == nil {
			content = buf.Bytes()
		} else {
			// Fallback to basic error HTML
			content = []byte(fmt.Sprintf("<html><body><h1>%d %s</h1></body></html>", statusCode, phrase))
		}
	} else {
		// Fallback to basic error HTML
		content = []byte(fmt.Sprintf("<html><body><h1>%d %s</h1></body></html>", statusCode, phrase))
	}
	
	// Create response
	response := fmt.Sprintf("HTTP/1.1 %d %s\r\n"+
		"Content-Length: %d\r\n"+
		"Content-Type: text/html\r\n"+
		"Connection: close\r\n"+
		"\r\n", statusCode, phrase, len(content))
	
	// Send response
	conn.Write([]byte(response))
	conn.Write(content)
	
	fmt.Printf("Sent error page: %d %s\n", statusCode, phrase)
}