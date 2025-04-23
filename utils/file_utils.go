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