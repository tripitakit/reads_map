# ReadsMap

ReadsMap is an Elixir CLI tool that visualizes reads aligned to a reference sequence. It takes a SAM/BAM file and a FASTA reference file as input and produces text, HTML or FASTA output formats, allowing for easy visualization and analysis of sequence alignments.
This tool has been developed mainly to test the functionalities of the [sam_parser](https://github.com/tripitakit/sam_parser.git) library, which is used to read and parse the input SAM/BAM files, but it can be useful in visualizing and documenting the alignment of reads to a reference sequence.

## Features

- Creates text-based visualization for terminal display or text files (default)
- Generates HTML visualizations with color-coded nucleotides
- Produces FASTA format output with properly aligned sequences
- Aligns reads to the reference sequence based on CIGAR strings
- Shows reference sequence at the top and reads aligned below
- Displays position markers for easy location reference
- Shows CIGAR string information for each read

## Current Limitations

- **Read Orientation**: Currently, ReadsMap only displays reads that are in the same orientation as the reference sequence (forward strand). Reads aligned to the reverse strand are filtered out in the current version. This limitation will be addressed in a future update to display reads in both orientations.

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

# Generate FASTA output
./reads_map [SAM/BAM file] [Reference FASTA] -f fasta

# Specify custom output file
./reads_map [SAM/BAM file] [Reference FASTA] -o output_file.txt
```

### Options

- `-o, --output PATH`: Path to save output (default: "output.txt", "output.html", or "output.fasta")
- `-f, --format TYPE`: Output format: "txt", "html", or "fasta" (default: "txt")
- `-h, --help`: Display help message

### Examples

```bash
./reads_map sample.bam reference.fasta -f html -o alignment.html
./reads_map sample.bam reference.fasta -f fasta -o alignment.fasta
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

## FASTA Output

The FASTA output provides a standard bioinformatics format representation of the alignment:
- Reference sequence with the proper FASTA header
- All aligned reads in FASTA format with their positions and CIGAR strings in the header lines
- Sequences wrapped at 60 characters per line for readability
- Gap characters (-) maintained for alignment consistency
- Compatible with other bioinformatics tools for further analysis

## Dependencies

ReadsMap relies on one dependency:

- [sam_parser](https://github.com/tripitakit/sam_parser.git) - For reading and parsing SAM/BAM files


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
De Marta, P. (2025). ReadsMap: A tool for visualizing SAM/BAM alignments.
https://github.com/tripitakit/reads_map
```

## Contact

Author: Patrick De Marta  
Email: patrick.demarta@gmail.com