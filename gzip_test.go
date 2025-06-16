package gzip

import (
	"testing"
)

func TestCompress(t *testing.T) {
	tests := []struct {
		name    string
		input   string
		wantErr bool
	}{
		{
			name:    "valid input",
			input:   "Hello, World!",
			wantErr: false,
		},
		{
			name:    "empty input",
			input:   "",
			wantErr: true,
		},
		{
			name:    "long input",
			input:   "This is a longer string that should be compressed. It contains multiple sentences and some special characters: !@#$%^&*()",
			wantErr: false,
		},
	}

	g := &Gzip{}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got, err := g.Compress(tt.input)
			if (err != nil) != tt.wantErr {
				t.Errorf("Compress() error = %v, wantErr %v", err, tt.wantErr)
				return
			}
			if !tt.wantErr {
				if !g.IsGzipped(got) {
					t.Error("Compress() output is not gzipped")
				}
				decompressed, err := g.Decompress(got)
				if err != nil {
					t.Errorf("Decompress() error = %v", err)
					return
				}
				if decompressed != tt.input {
					t.Errorf("Decompress() = %v, want %v", decompressed, tt.input)
				}
			}
		})
	}
}

func TestCompressBytes(t *testing.T) {
	tests := []struct {
		name    string
		input   []byte
		wantErr bool
	}{
		{
			name:    "valid input",
			input:   []byte("Hello, World!"),
			wantErr: false,
		},
		{
			name:    "empty input",
			input:   []byte{},
			wantErr: true,
		},
		{
			name:    "binary input",
			input:   []byte{0x00, 0x01, 0x02, 0x03, 0x04, 0x05},
			wantErr: false,
		},
	}

	g := &Gzip{}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got, err := g.CompressBytes(tt.input)
			if (err != nil) != tt.wantErr {
				t.Errorf("CompressBytes() error = %v, wantErr %v", err, tt.wantErr)
				return
			}
			if !tt.wantErr {
				if !g.IsGzippedBytes(got) {
					t.Error("CompressBytes() output is not gzipped")
				}
				decompressed, err := g.DecompressBytes(got)
				if err != nil {
					t.Errorf("DecompressBytes() error = %v", err)
					return
				}
				if string(decompressed) != string(tt.input) {
					t.Errorf("DecompressBytes() = %v, want %v", decompressed, tt.input)
				}
			}
		})
	}
}

func TestDecompress(t *testing.T) {
	g := &Gzip{}
	original := "Hello, World!"
	compressed, err := g.Compress(original)
	if err != nil {
		t.Fatalf("Failed to compress test data: %v", err)
	}

	tests := []struct {
		name    string
		input   string
		want    string
		wantErr bool
	}{
		{
			name:    "valid compressed data",
			input:   compressed,
			want:    original,
			wantErr: false,
		},
		{
			name:    "empty input",
			input:   "",
			want:    "",
			wantErr: true,
		},
		{
			name:    "invalid compressed data",
			input:   "not gzipped data",
			want:    "",
			wantErr: true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got, err := g.Decompress(tt.input)
			if (err != nil) != tt.wantErr {
				t.Errorf("Decompress() error = %v, wantErr %v", err, tt.wantErr)
				return
			}
			if !tt.wantErr && got != tt.want {
				t.Errorf("Decompress() = %v, want %v", got, tt.want)
			}
		})
	}
}

func TestDecompressBytes(t *testing.T) {
	g := &Gzip{}
	original := []byte("Hello, World!")
	compressed, err := g.CompressBytes(original)
	if err != nil {
		t.Fatalf("Failed to compress test data: %v", err)
	}

	tests := []struct {
		name    string
		input   []byte
		want    []byte
		wantErr bool
	}{
		{
			name:    "valid compressed data",
			input:   compressed,
			want:    original,
			wantErr: false,
		},
		{
			name:    "empty input",
			input:   []byte{},
			want:    nil,
			wantErr: true,
		},
		{
			name:    "invalid compressed data",
			input:   []byte("not gzipped data"),
			want:    nil,
			wantErr: true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got, err := g.DecompressBytes(tt.input)
			if (err != nil) != tt.wantErr {
				t.Errorf("DecompressBytes() error = %v, wantErr %v", err, tt.wantErr)
				return
			}
			if !tt.wantErr && string(got) != string(tt.want) {
				t.Errorf("DecompressBytes() = %v, want %v", got, tt.want)
			}
		})
	}
}

func TestIsGzipped(t *testing.T) {
	g := &Gzip{}
	compressed, err := g.Compress("test data")
	if err != nil {
		t.Fatalf("Failed to compress test data: %v", err)
	}

	tests := []struct {
		name  string
		input string
		want  bool
	}{
		{
			name:  "gzipped data",
			input: compressed,
			want:  true,
		},
		{
			name:  "empty string",
			input: "",
			want:  false,
		},
		{
			name:  "non-gzipped data",
			input: "not gzipped data",
			want:  false,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			if got := g.IsGzipped(tt.input); got != tt.want {
				t.Errorf("IsGzipped() = %v, want %v", got, tt.want)
			}
		})
	}
}

func TestIsGzippedBytes(t *testing.T) {
	g := &Gzip{}
	compressed, err := g.CompressBytes([]byte("test data"))
	if err != nil {
		t.Fatalf("Failed to compress test data: %v", err)
	}

	tests := []struct {
		name  string
		input []byte
		want  bool
	}{
		{
			name:  "gzipped data",
			input: compressed,
			want:  true,
		},
		{
			name:  "empty bytes",
			input: []byte{},
			want:  false,
		},
		{
			name:  "non-gzipped data",
			input: []byte("not gzipped data"),
			want:  false,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			if got := g.IsGzippedBytes(tt.input); got != tt.want {
				t.Errorf("IsGzippedBytes() = %v, want %v", got, tt.want)
			}
		})
	}
}
