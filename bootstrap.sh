#!/bin/bash

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if Go is installed
check_go() {
    print_status "Checking if Go is installed..."
    if ! command -v go &> /dev/null; then
        print_error "Go is not installed. Please install Go first: https://golang.org/dl/"
        exit 1
    fi
    GO_VERSION=$(go version | cut -d' ' -f3)
    print_success "Go is installed: $GO_VERSION"
}

# Setup project directory
setup_project() {
    print_status "Setting up project directory..."
    
    PROJECT_DIR="xk6-gzip"
    
    # Remove existing directory if it exists
    if [ -d "$PROJECT_DIR" ]; then
        print_warning "Directory $PROJECT_DIR already exists. Removing it..."
        rm -rf "$PROJECT_DIR"
    fi
    
    mkdir "$PROJECT_DIR"
    cd "$PROJECT_DIR"
    print_success "Created and entered directory: $PROJECT_DIR"
}

# Initialize Go module
init_go_module() {
    print_status "Initializing Go module..."
    go mod init xk6-gzip
    print_success "Go module initialized"
}

# Install dependencies
install_dependencies() {
    print_status "Installing k6 dependencies..."
    go get go.k6.io/k6@latest
    print_success "k6 dependencies installed"
    
    print_status "Tidying up dependencies..."
    go mod tidy
    print_success "Dependencies tidied"
}

# Create the gzip extension Go file
create_gzip_extension() {
    print_status "Creating gzip.go extension file..."
    cat > gzip.go << 'EOF'
package gzip

import (
	"bytes"
	"compress/gzip"
	"fmt"
	"io"
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
	writer := gzip.NewWriter(&buf)

	_, err := writer.Write([]byte(input))
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
	writer := gzip.NewWriter(&buf)

	_, err := writer.Write(input)
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
EOF
    print_success "Created gzip.go extension file"
}

# Create the test JavaScript file
create_test_file() {
    print_status "Creating test-gzip.js test file..."
    cat > test-gzip.js << 'EOF'
import gzip from 'k6/x/gzip';

export default function () {
  // Test string compression and decompression
  const originalText = "This is a test string that we want to compress using gzip!";
  
  console.log(`Original text: "${originalText}"`);
  console.log(`Original length: ${originalText.length} bytes`);
  
  try {
    // Compress the string
    const compressed = gzip.compress(originalText);
    console.log(`Compressed length: ${compressed.length} bytes`);
    
    // Check if data is gzipped
    const isGzipped = gzip.isGzipped(compressed);
    console.log(`Is compressed data gzipped? ${isGzipped}`);
    
    // Decompress the string
    const decompressed = gzip.decompress(compressed);
    console.log(`Decompressed text: "${decompressed}"`);
    console.log(`Decompressed length: ${decompressed.length} bytes`);
    
    // Verify the data matches
    const matches = originalText === decompressed;
    console.log(`Original matches decompressed? ${matches}`);
    
    if (matches) {
      console.log("✅ Compression and decompression successful!");
    } else {
      console.log("❌ Data corruption detected!");
    }
    
    // Calculate compression ratio
    const compressionRatio = ((originalText.length - compressed.length) / originalText.length * 100).toFixed(2);
    console.log(`Compression ratio: ${compressionRatio}%`);
    
  } catch (error) {
    console.error(`Error during compression/decompression: ${error}`);
  }
  
  // Test with larger text for better compression
  const largeText = "Lorem ipsum dolor sit amet, consectetur adipiscing elit. ".repeat(100);
  
  try {
    console.log(`\n--- Large text test ---`);
    console.log(`Large text length: ${largeText.length} bytes`);
    
    const compressedLarge = gzip.compress(largeText);
    console.log(`Compressed large text length: ${compressedLarge.length} bytes`);
    
    const compressionRatioLarge = ((largeText.length - compressedLarge.length) / largeText.length * 100).toFixed(2);
    console.log(`Large text compression ratio: ${compressionRatioLarge}%`);
    
    const decompressedLarge = gzip.decompress(compressedLarge);
    const largeMatches = largeText === decompressedLarge;
    console.log(`Large text matches? ${largeMatches}`);
    
  } catch (error) {
    console.error(`Error during large text compression: ${error}`);
  }
}
EOF
    print_success "Created test-gzip.js test file"
}

# Install xk6 tool
install_xk6() {
    print_status "Installing xk6 tool..."
    go install go.k6.io/xk6/cmd/xk6@latest
    print_success "xk6 tool installed"
}

# Find xk6 binary location
find_xk6() {
    # Try to find xk6 in common locations
    local xk6_path=""
    
    # Check if xk6 is in PATH
    if command -v xk6 &> /dev/null; then
        xk6_path="xk6"
    else
        # Try GOPATH/bin
        local gopath=$(go env GOPATH)
        if [ -f "$gopath/bin/xk6" ]; then
            xk6_path="$gopath/bin/xk6"
        elif [ -f "$gopath/bin/xk6.exe" ]; then
            xk6_path="$gopath/bin/xk6.exe"
        # Try GOROOT/bin
        else
            local goroot=$(go env GOROOT)
            if [ -f "$goroot/bin/xk6" ]; then
                xk6_path="$goroot/bin/xk6"
            elif [ -f "$goroot/bin/xk6.exe" ]; then
                xk6_path="$goroot/bin/xk6.exe"
            fi
        fi
    fi
    
    if [ -z "$xk6_path" ]; then
        print_error "Could not find xk6 binary. Please add \$(go env GOPATH)/bin to your PATH"
        print_warning "You can add this to your shell profile:"
        echo "export PATH=\$PATH:\$(go env GOPATH)/bin"
        exit 1
    fi
    
    echo "$xk6_path"
}

# Build custom k6 binary with gzip extension
build_k6() {
    print_status "Building custom k6 binary with gzip extension..."
    
    local xk6_binary=$(find_xk6)
    print_status "Using xk6 at: $xk6_binary"
    
    "$xk6_binary" build --with xk6-gzip=.
    
    # Check if build was successful
    if [ -f "./k6" ] || [ -f "./k6.exe" ]; then
        print_success "Custom k6 binary built successfully"
    else
        print_error "Failed to build k6 binary"
        exit 1
    fi
}

# Run the test
run_test() {
    print_status "Running gzip extension test..."
    
    # Determine the correct binary name
    K6_BINARY="./k6"
    if [ -f "./k6.exe" ]; then
        K6_BINARY="./k6.exe"
    fi
    
    echo -e "\n${BLUE}========== TEST OUTPUT ==========${NC}"
    $K6_BINARY run test-gzip.js
    echo -e "${BLUE}=================================${NC}\n"
    
    print_success "Test completed successfully!"
}

# Show final instructions
show_instructions() {
    print_success "Setup completed! Here's what was created:"
    echo ""
    echo "📁 Project directory: $(pwd)"
    echo "📄 Files created:"
    echo "   - gzip.go (Go extension code)"
    echo "   - test-gzip.js (JavaScript test file)"
    echo "   - k6 or k6.exe (custom k6 binary)"
    echo "   - go.mod and go.sum (Go module files)"
    echo ""
    echo "🚀 To run tests again:"
    echo "   ./k6 run test-gzip.js"
    echo ""
    echo "🔧 To modify the extension:"
    echo "   1. Edit gzip.go"
    echo "   2. Run: \$(go env GOPATH)/bin/xk6 build --with xk6-gzip=."
    echo "   3. Run: ./k6 run test-gzip.js"
    echo ""
    echo "💡 Tip: To use xk6 directly, add Go bin to your PATH:"
    echo "   export PATH=\$PATH:\$(go env GOPATH)/bin"
    echo "   Then you can use: xk6 build --with xk6-gzip=."
}

# Main execution
main() {
    print_status "Starting k6 gzip extension setup..."
    echo ""
    
    check_go
    setup_project
    init_go_module
    install_dependencies
    create_gzip_extension
    create_test_file
    install_xk6
    build_k6
    run_test
    show_instructions
    
    print_success "All done! 🎉"
}

# Run main function
main "$@"