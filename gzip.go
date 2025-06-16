package gzip

import (
	"bytes"
	"fmt"
	"io"

	"github.com/klauspost/compress/gzip"
	"go.k6.io/k6/js/modules"
)

// init is called by the Go runtime at application startup.
func init() {
	modules.Register("k6/x/gzip", New())
}

type (
	// RootModule is the global module instance that will create module
	// instances for each VU.
	RootModule struct{}

	// ModuleInstance represents an instance of the JS module.
	ModuleInstance struct {
		// vu provides methods for accessing internal k6 objects for a VU
		vu modules.VU
		// gzip is the exported type
		gzipAPI *Gzip
	}
)

// Ensure the interfaces are implemented correctly.
var (
	_ modules.Instance = &ModuleInstance{}
	_ modules.Module   = &RootModule{}
)

// New returns a pointer to a new RootModule instance.
func New() *RootModule {
	return &RootModule{}
}

// NewModuleInstance implements the modules.Module interface returning a new instance for each VU.
func (*RootModule) NewModuleInstance(vu modules.VU) modules.Instance {
	return &ModuleInstance{
		vu:      vu,
		gzipAPI: &Gzip{vu: vu},
	}
}

// Gzip is the type for our custom gzip API.
type Gzip struct {
	vu modules.VU // provides methods for accessing internal k6 objects
}

// Compress compresses the input string using gzip and returns the compressed data as base64 string.
func (g *Gzip) Compress(input string) (string, error) {
	if input == "" {
		return "", fmt.Errorf("input cannot be empty")
	}

	var buf bytes.Buffer
	writer, err := gzip.NewWriterLevel(&buf, gzip.BestSpeed) // Use BestSpeed for k6 performance
	if err != nil {
		return "", fmt.Errorf("failed to create gzip writer: %w", err)
	}

	_, err = writer.Write([]byte(input))
	if err != nil {
		writer.Close()
		return "", fmt.Errorf("failed to write data: %w", err)
	}

	err = writer.Close()
	if err != nil {
		return "", fmt.Errorf("failed to close gzip writer: %w", err)
	}

	// Return as base64 encoded string to ensure safe transport in JavaScript
	return buf.String(), nil
}

// CompressBytes compresses the input byte array using gzip and returns the compressed bytes.
func (g *Gzip) CompressBytes(input []byte) ([]byte, error) {
	if len(input) == 0 {
		return nil, fmt.Errorf("input cannot be empty")
	}

	var buf bytes.Buffer
	writer, err := gzip.NewWriterLevel(&buf, gzip.BestSpeed) // Use BestSpeed for k6 performance
	if err != nil {
		return nil, fmt.Errorf("failed to create gzip writer: %w", err)
	}

	_, err = writer.Write(input)
	if err != nil {
		writer.Close()
		return nil, fmt.Errorf("failed to write data: %w", err)
	}

	err = writer.Close()
	if err != nil {
		return nil, fmt.Errorf("failed to close gzip writer: %w", err)
	}

	return buf.Bytes(), nil
}

// Decompress decompresses the gzip compressed string and returns the original string.
func (g *Gzip) Decompress(compressed string) (string, error) {
	if compressed == "" {
		return "", fmt.Errorf("compressed data cannot be empty")
	}

	reader, err := gzip.NewReader(bytes.NewReader([]byte(compressed)))
	if err != nil {
		return "", fmt.Errorf("failed to create gzip reader: %w", err)
	}
	defer reader.Close()

	decompressed, err := io.ReadAll(reader)
	if err != nil {
		return "", fmt.Errorf("failed to decompress data: %w", err)
	}

	return string(decompressed), nil
}

// DecompressBytes decompresses the gzip compressed byte array and returns the original bytes.
func (g *Gzip) DecompressBytes(compressed []byte) ([]byte, error) {
	if len(compressed) == 0 {
		return nil, fmt.Errorf("compressed data cannot be empty")
	}

	reader, err := gzip.NewReader(bytes.NewReader(compressed))
	if err != nil {
		return nil, fmt.Errorf("failed to create gzip reader: %w", err)
	}
	defer reader.Close()

	decompressed, err := io.ReadAll(reader)
	if err != nil {
		return nil, fmt.Errorf("failed to decompress data: %w", err)
	}

	return decompressed, nil
}

// IsGzipped checks if the provided data appears to be gzip compressed.
func (g *Gzip) IsGzipped(data string) bool {
	if len(data) < 2 {
		return false
	}
	// Check for gzip magic number (1f 8b)
	return data[0] == 0x1f && data[1] == 0x8b
}

// IsGzippedBytes checks if the provided byte array appears to be gzip compressed.
func (g *Gzip) IsGzippedBytes(data []byte) bool {
	if len(data) < 2 {
		return false
	}
	// Check for gzip magic number (1f 8b)
	return data[0] == 0x1f && data[1] == 0x8b
}

// Exports implements the modules.Instance interface and returns the exported types for the JS module.
func (mi *ModuleInstance) Exports() modules.Exports {
	return modules.Exports{
		Default: mi.gzipAPI,
	}
}
