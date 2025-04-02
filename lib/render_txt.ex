defmodule ReadsMap.RenderTxt do
  @moduledoc """
  Module responsible for rendering text output for read alignments.
  Provides functions to generate plain text visualization of sequence alignments
  for terminal display or saving to a text file.
  """

  @doc """
  Generates a text representation of the alignment for console output or saving to file.

  ## Parameters
    * `ref_seq` - The reference sequence
    * `reads` - Processed reads with alignment information
    * `sam_path` - Path to the SAM/BAM file (optional)
    * `ref_path` - Path to the FASTA reference file (optional)
  """
  def generate_txt(ref_seq, reads, sam_path \\ nil, ref_path \\ nil) do
    # Get max length needed for labels to align text nicely
    max_label_width = calculate_max_label_width(reads)

    # Generate position markers
    position_markers = generate_position_markers(String.length(ref_seq), max_label_width)

    # Generate the reference row
    reference_row = format_reference_row(ref_seq, max_label_width)

    # Generate read rows
    read_rows = generate_read_rows(reads, max_label_width)

    # Format input file information
    input_files_info = format_input_files_info(sam_path, ref_path)

    # Combine all elements
    [
      "ReadsMap v0.1 (02/04/2025)",
      "https://github.com/tripitakit/reads_map.git - Patrick De Marta",
      "",
      input_files_info,
      "",
      position_markers,
      reference_row,
      ""  # Empty line after reference
    ] ++ read_rows
    |> Enum.join("\n")
  end

  @doc """
  Formats input file information for display in the header.
  """
  def format_input_files_info(sam_path, ref_path) do
    sam_info = if sam_path, do: "Input SAM/BAM: #{sam_path}", else: "Input SAM/BAM: not specified"
    ref_info = if ref_path, do: "Reference FASTA: #{ref_path}", else: "Reference FASTA: not specified"
    "#{sam_info}\n#{ref_info}"
  end

  @doc """
  Generates position markers to help identify sequence positions.
  """
  def generate_position_markers(length, label_width) do
    # Create top line markers for every 10 positions
    markers = Enum.map(1..div(length, 10) + 1, fn i ->
      pos = i * 10
      if pos <= length, do: "|#{String.pad_leading("#{pos}", 9)}", else: ""
    end)
    |> Enum.join("")

    # Add padding to align with reference sequence
    padding = String.duplicate(" ", label_width + 1)  # +1 for the space after the label
    "#{padding}#{markers}"
  end

  @doc """
  Format the reference sequence row with proper labeling.
  """
  def format_reference_row(ref_seq, label_width) do
    label = "Reference:"
    padding = String.duplicate(" ", label_width - String.length(label))
    "#{label}#{padding} #{ref_seq}"
  end

  @doc """
  Generates text rows for all reads.
  """
  def generate_read_rows(reads, label_width) do
    reads
    |> Enum.map(fn read ->
      read_label = "#{read.qname} (#{read.position}):"
      # Adjust padding based on label width
      padding = String.duplicate(" ", max(0, label_width - String.length(read_label)))

      # Format CIGAR string
      cigar_info = " [CIGAR: #{read.cigar}]"

      "#{read_label}#{padding} #{read.sequence}#{cigar_info}"
    end)
  end

  @doc """
  Calculate the width needed for labels to align all sequences properly.
  """
  def calculate_max_label_width(reads) do
    reference_width = String.length("Reference:")

    read_max_width = reads
    |> Enum.map(fn read ->
      String.length("#{read.qname} (#{read.position}):")
    end)
    |> Enum.max(fn -> 0 end)

    # Get the maximum, with a minimum of 20 characters
    max(max(reference_width, read_max_width), 20)
  end

  @doc """
  Calculate padding needed for position markers.
  """
  def calculate_label_padding do
    # Standard label padding to match reference alignment
    20
  end
end
