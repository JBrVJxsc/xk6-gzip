# k6 Gzip Extension

A k6 extension that provides gzip compression and decompression capabilities for performance testing scenarios involving compressed data transfers.

## Features

- ✅ **String compression/decompression** - Handle text data with gzip
- ✅ **Binary data support** - Compress/decompress byte arrays
- ✅ **Data validation** - Check if data is gzip compressed
- ✅ **Error handling** - Graceful error handling with descriptive messages
- ✅ **High performance** - Built with Go's native gzip package
- ✅ **Thread-safe** - Safe for concurrent use across multiple VUs

## Use Cases

- **API Testing**: Test endpoints that accept/return gzipped content
- **Performance Testing**: Simulate compressed payload transfers
- **Data Validation**: Verify gzip compression/decompression in applications
- **Load Testing**: Reduce bandwidth usage by compressing test payloads
- **Real-world Simulation**: Mirror production scenarios with compression

## Installation

### Prerequisites

- [Go](https://golang.org/dl/) 1.19 or later
- [Git](https://git-scm.com/)

### Quick Setup

Use our automated setup script:

```bash
curl -sSL https://raw.githubusercontent.com/yourusername/xk6-gzip/main/setup-k6-gzip.sh | bash
```

### Manual Installation

1. **Clone or create the extension:**
   ```bash
   mkdir xk6-gzip && cd xk6-gzip
   go mod init xk6-gzip
   ```

2. **Install dependencies:**
   ```bash
   go get go.k6.io/k6@latest
   go mod tidy
   ```

3. **Create the extension file** (`gzip.go`) with the provided code

4. **Install xk6:**
   ```bash
   go install go.k6.io/xk6/cmd/xk6@latest
   ```

5. **Build custom k6 binary:**
   ```bash
   xk6 build --with xk6-gzip=.
   ```

6. **Run tests:**
   ```bash
   ./k6 run your-test.js
   ```

## API Reference

### Import

```javascript
import gzip from 'k6/x/gzip';
```

### Methods

#### `compress(input: string): string`

Compresses a string using gzip compression.

**Parameters:**
- `input` (string): The string to compress

**Returns:**
- `string`: The compressed data

**Example:**
```javascript
const originalText = "Hello, World!";
const compressed = gzip.compress(originalText);
console.log(`Original: ${originalText.length} bytes, Compressed: ${compressed.length} bytes`);
```

#### `decompress(compressed: string): string`

Decompresses gzip-compressed data back to the original string.

**Parameters:**
- `compressed` (string): The gzip-compressed data

**Returns:**
- `string`: The original decompressed string

**Example:**
```javascript
const compressed = gzip.compress("Hello, World!");
const decompressed = gzip.decompress(compressed);
console.log(`Decompressed: ${decompressed}`); // "Hello, World!"
```

#### `compressBytes(input: []byte): []byte`

Compresses a byte array using gzip compression.

**Parameters:**
- `input` ([]byte): The byte array to compress

**Returns:**
- `[]byte`: The compressed byte array

#### `decompressBytes(compressed: []byte): []byte`

Decompresses gzip-compressed byte array back to the original bytes.

**Parameters:**
- `compressed` ([]byte): The gzip-compressed byte array

**Returns:**
- `[]byte`: The original decompressed byte array

#### `isGzipped(data: string): boolean`

Checks if the provided string appears to be gzip compressed by examining the magic number.

**Parameters:**
- `data` (string): The data to check

**Returns:**
- `boolean`: `true` if data appears to be gzipped, `false` otherwise

**Example:**
```javascript
const text = "Hello, World!";
const compressed = gzip.compress(text);

console.log(gzip.isGzipped(text));       // false
console.log(gzip.isGzipped(compressed)); // true
```

#### `isGzippedBytes(data: []byte): boolean`

Checks if the provided byte array appears to be gzip compressed.

**Parameters:**
- `data` ([]byte): The byte array to check

**Returns:**
- `boolean`: `true` if data appears to be gzipped, `false` otherwise

## Usage Examples

### Basic Compression/Decompression

```javascript
import gzip from 'k6/x/gzip';

export default function () {
  const originalText = "This is a test string for compression!";
  
  try {
    // Compress the string
    const compressed = gzip.compress(originalText);
    console.log(`Compression: ${originalText.length} → ${compressed.length} bytes`);
    
    // Decompress back to original
    const decompressed = gzip.decompress(compressed);
    console.log(`Match: ${originalText === decompressed}`);
    
    // Calculate compression ratio
    const ratio = ((originalText.length - compressed.length) / originalText.length * 100).toFixed(2);
    console.log(`Compression ratio: ${ratio}%`);
    
  } catch (error) {
    console.error(`Error: ${error}`);
  }
}
```

### Testing Compressed API Endpoints

```javascript
import http from 'k6/http';
import gzip from 'k6/x/gzip';

export default function () {
  // Prepare test data
  const payload = JSON.stringify({
    message: "Large test data ".repeat(100),
    timestamp: new Date().toISOString()
  });
  
  // Compress payload
  const compressedPayload = gzip.compress(payload);
  console.log(`Payload size reduction: ${payload.length} → ${compressedPayload.length} bytes`);
  
  // Send compressed data to API
  const response = http.post('https://api.example.com/data', compressedPayload, {
    headers: {
      'Content-Type': 'application/json',
      'Content-Encoding': 'gzip',
    },
  });
  
  // Check if response is compressed
  if (gzip.isGzipped(response.body)) {
    const decompressedResponse = gzip.decompress(response.body);
    console.log(`Decompressed response: ${decompressedResponse}`);
  }
}
```

### Performance Comparison

```javascript
import gzip from 'k6/x/gzip';

export default function () {
  // Test different data sizes
  const testSizes = [100, 1000, 10000, 100000];
  
  testSizes.forEach(size => {
    const testData = "Lorem ipsum dolor sit amet. ".repeat(size);
    
    console.log(`\nTesting ${size} repetitions:`);
    console.log(`Original size: ${testData.length} bytes`);
    
    // Measure compression time and ratio
    const startTime = Date.now();
    const compressed = gzip.compress(testData);
    const compressionTime = Date.now() - startTime;
    
    const ratio = ((testData.length - compressed.length) / testData.length * 100).toFixed(2);
    
    console.log(`Compressed size: ${compressed.length} bytes`);
    console.log(`Compression ratio: ${ratio}%`);
    console.log(`Compression time: ${compressionTime}ms`);
    
    // Verify decompression
    const decompressed = gzip.decompress(compressed);
    console.log(`Decompression successful: ${testData === decompressed}`);
  });
}
```

### Data Validation Pipeline

```javascript
import gzip from 'k6/x/gzip';

export default function () {
  const testCases = [
    "Short text",
    "Medium length text with some repetition. ".repeat(10),
    "Very long text with lots of repetition. ".repeat(1000),
    '{"json": "data", "with": ["arrays", "and", "objects"]}',
    // Binary-like data
    String.fromCharCode(...Array.from({length: 1000}, (_, i) => i % 256))
  ];
  
  testCases.forEach((testCase, index) => {
    console.log(`\nTest case ${index + 1}:`);
    
    try {
      // Test the full pipeline
      const compressed = gzip.compress(testCase);
      const isCompressed = gzip.isGzipped(compressed);
      const decompressed = gzip.decompress(compressed);
      const isValid = testCase === decompressed;
      
      console.log(`Original length: ${testCase.length}`);
      console.log(`Compressed length: ${compressed.length}`);
      console.log(`Is gzipped: ${isCompressed}`);
      console.log(`Validation passed: ${isValid}`);
      
      if (!isValid) {
        console.error("❌ Data corruption detected!");
      } else {
        console.log("✅ Pipeline successful");
      }
      
    } catch (error) {
      console.error(`❌ Error in test case ${index + 1}: ${error}`);
    }
  });
}
```

## Error Handling

The extension provides descriptive error messages for common issues:

```javascript
import gzip from 'k6/x/gzip';

export default function () {
  try {
    // This will throw an error
    gzip.compress("");
  } catch (error) {
    console.log(`Error: ${error}`); // "input cannot be empty"
  }
  
  try {
    // This will also throw an error
    gzip.decompress("invalid gzip data");
  } catch (error) {
    console.log(`Error: ${error}`); // "failed to create gzip reader: ..."
  }
}
```

## Building from Source

### Development Setup

1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/xk6-gzip.git
   cd xk6-gzip
   ```

2. Install dependencies:
   ```bash
   go mod tidy
   ```

3. Build the extension:
   ```bash
   xk6 build --with xk6-gzip=.
   ```

### Building for Different Platforms

```bash
# Linux
GOOS=linux GOARCH=amd64 xk6 build --with xk6-gzip=.

# Windows
GOOS=windows GOARCH=amd64 xk6 build --with xk6-gzip=.

# macOS
GOOS=darwin GOARCH=amd64 xk6 build --with xk6-gzip=.
```

## Troubleshooting

### Common Issues

#### `xk6: command not found`

**Solution:** Add Go's bin directory to your PATH:
```bash
export PATH=$PATH:$(go env GOPATH)/bin
```

#### Module path errors during build

**Solution:** Use absolute paths in the build command:
```bash
xk6 build --with "xk6-gzip=$(pwd)"
```

#### Import errors in IDE

**Solution:** Run `go mod tidy` and restart your IDE.

### Performance Considerations

- **Large Data**: For very large datasets, consider streaming compression
- **Memory Usage**: Compression requires additional memory proportional to input size
- **CPU Usage**: Compression is CPU-intensive; monitor VU resource usage
- **Compression Ratio**: Highly repetitive data compresses better

### Debug Mode

Enable debug logging for troubleshooting:

```javascript
import gzip from 'k6/x/gzip';

export default function () {
  console.log("Debug: Starting compression test");
  
  const text = "Debug test data";
  console.log(`Debug: Original text length: ${text.length}`);
  
  const compressed = gzip.compress(text);
  console.log(`Debug: Compressed length: ${compressed.length}`);
  
  const decompressed = gzip.decompress(compressed);
  console.log(`Debug: Decompressed matches: ${text === decompressed}`);
}
```

## Contributing

We welcome contributions! Please see our [Contributing Guidelines](CONTRIBUTING.md) for details.

### Development Process

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests
5. Submit a pull request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

- **Issues**: [GitHub Issues](https://github.com/yourusername/xk6-gzip/issues)
- **Discussions**: [GitHub Discussions](https://github.com/yourusername/xk6-gzip/discussions)
- **k6 Community**: [k6 Community Forum](https://community.grafana.com/c/grafana-k6/66)

## Changelog

### v1.0.0
- Initial release
- Basic compression/decompression functionality
- Binary data support
- Data validation methods
- Comprehensive error handling

---

**Made with ❤️ for the k6 community**
