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
