# ReadsMap

ReadsMap is a tool that visualizes reads aligned to a reference sequence. It takes a SAM/BAM file and a FASTA reference file as input and produces either HTML or text output formats, allowing for easy visualization of sequence alignments.

![ReadsMap Logo](https://github.com/tripitakit/reads_map/raw/main/assets/logo.png)

## Features

- Creates text-based visualization for terminal display or text files (default)
- Generates HTML visualizations with color-coded nucleotides
  - A is represented in red
  - C is represented in green
  - G is represented in blue
  - T is represented in yellow
  - Gaps (-) are represented in gray
- Aligns reads to the reference sequence based on CIGAR strings
- Shows reference sequence at the top and reads aligned below
- Displays position markers for easy location reference
- Shows CIGAR string information for each read

## Installation

### Prerequisites

- Erlang/OTP 25 or later
- Elixir 1.14 or later

### From Source

1. Clone the repository:

```bash
git clone https://github.com/tripitakit/reads_map.git
cd reads_map
```

2. Fetch dependencies:

```bash
mix deps.get
```

3. Build the executable:

```bash
mix escript.build
```

4. (Optional) Add to your PATH:

```bash
# Add to your ~/.bashrc or ~/.zshrc
export PATH="$PATH:/path/to/reads_map"
```

## Usage

```bash
# Show help
./reads_map --help

# Generate text output (default)
./reads_map [SAM/BAM file] [Reference FASTA]

# Generate HTML output
./reads_map [SAM/BAM file] [Reference FASTA] -f html

# Specify custom output file
./reads_map [SAM/BAM file] [Reference FASTA] -o output_file.txt
```

### Options

- `-o, --output PATH`: Path to save output (default: "output.txt" or "output.html")
- `-f, --format TYPE`: Output format: "txt" or "html" (default: "txt")
- `-h, --help`: Display help message

### Example

```bash
./reads_map input/sample.bam input/reference.fasta -f html -o alignment.html
```

## Text Output

The text output provides a simple representation suitable for terminals or text editors:
- Position markers above the reference sequence
- Reference sequence with read alignments below
- Read names, positions, and CIGAR strings displayed
- File paths displayed in the header

## HTML Output

The HTML output provides a visually appealing representation of the alignment:
- Reference sequence at the top followed by aligned reads
- Color-coded nucleotides for easy visualization
- Read names and positions displayed
- CIGAR string information for each read
- Position markers to easily locate positions in the sequence

## Dependencies

ReadsMap relies on two primary dependencies:

- [sam_parser](https://github.com/tripitakit/sam_parser.git) - For reading and parsing SAM/BAM files
- [bio_elixir](https://github.com/tripitakit/bio_elixir.git) - For reading and parsing FASTA reference files

## License

ReadsMap is licensed under the GNU General Public License v3.0 (GPL-3.0).

See [COPYING](COPYING) for the full text of the license.

## Author

Patrick De Marta ([@tripitakit](https://github.com/tripitakit))

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the project
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## Issues

If you encounter any problems or have suggestions, please [open an issue](https://github.com/tripitakit/reads_map/issues) on GitHub.

## Citation

If you use ReadsMap in your research, please cite:

```
De Marta, P. (2025). ReadsMap: A tool for visualizing sequence alignments.
https://github.com/tripitakit/reads_map
```

