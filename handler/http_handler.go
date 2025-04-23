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