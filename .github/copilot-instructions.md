This is an Elixir program that reads a sam/bam file and a fasta reference sequence to produce an html view of the reads aligned to the reference sequence.

The library takes a sam/bam file as input and parses it to extract the reads aligned to a reference sequence. It then generates an HTML view of the reads mapped onto the reference sequence, allowing for easy visualization of the alignment.

The reference sequence is the first line of the view
Each read is on a single line, aligned to the reference sequence
The reads are represented as a series of characters, with each character corresponding to a nucleotide (A, C, G, T) or a gap (-) in the alignment.

The reads are color-coded based on their nucleotide position:
- A is represented in red
- C is represented in green
- G is represented in blue
- T is represented in yellow
- - is represented in gray

The reads are displayed in a table format, with the reference sequence at the top and the reads aligned below it. Each read is displayed in a separate row, with the nucleotide positions aligned to the reference sequence.
The program uses the library https://github.com/tripitakit/sam_parser.git to read and parse the sam/bam file and extract the reads aligned to the reference sequence.
The program uses the library https://github.com/tripitakit/bio_elixir.git to read and parse the fasta file of the reference sequence.

The program is designed to be used from the command line allowing users to pass the input sam/bam file and the input fasta reference as arguments, to produce the output html view with the alignment.

Use idiomatic Elixir code style and best practices.

Use the following libraries:
- sam_parser: https://github.com/tripitakit/sam_parser.git
- bio_elixir: https://github.com/tripitakit/bio_elixir.git





