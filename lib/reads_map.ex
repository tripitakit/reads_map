defmodule ReadsMap do
  @moduledoc """
  ReadsMap generates an HTML view of reads aligned to a reference sequence.
  It takes a SAM/BAM file and a FASTA reference file as input.
  """

  @doc """
  Main function that processes the SAM/BAM file and FASTA reference to produce an HTML view.

  ## Parameters

    * `sam_path` - Path to the SAM/BAM file
    * `ref_path` - Path to the FASTA reference file
    * `output_path` - Path to save the output HTML file (optional, defaults to "output.html")

  ## Returns

    * `{:ok, output_path}` - If the HTML was successfully generated
    * `{:error, reason}` - If there was an error processing the files
  """
  def main(sam_path, ref_path, output_path \\ "output.html") do
    with {:ok, reference} <- load_reference(ref_path),
         {:ok, alignments} <- load_alignments(sam_path) do

      html_content = generate_html(reference, alignments)

      case File.write(output_path, html_content) do
        :ok -> {:ok, output_path}
        {:error, reason} -> {:error, "Failed to write output file: #{reason}"}
      end
    end
  end

  @doc """
  Load the reference sequence from a FASTA file.
  """
  defp load_reference(ref_path) do
    try do
      [first_seq | _] = BioElixir.SeqIO.read_fasta_file(ref_path)
      %{display_id: _id, seq: seq} = first_seq
      {:ok, seq}
    rescue
      e -> {:error, "Failed to parse reference file: #{inspect(e)}"}
    end
  end

  @doc """
  Load alignments from a SAM/BAM file.
  """
  defp load_alignments(sam_path) do
    try do
      sam = SamParser.parse_file(sam_path)

      {:ok, sam.alignments}
    rescue
      e -> {:error, "Failed to parse SAM/BAM file: #{inspect(e)}"}
    end
  end

  @doc """
  Generate HTML content for the alignment visualization.
  """
  defp generate_html(ref_seq, alignments) do
    # Filter out reverse reads
    forward_alignments = Enum.filter(alignments, fn aln -> not SamParser.is_reverse?(aln) end)

    reads = process_alignments(forward_alignments, ref_seq)

    html_header = """
    <!DOCTYPE html>
    <html lang="en">
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <title>Reads Alignment Visualization</title>
      <style>
        body { font-family: monospace; }
        .container { overflow-x: auto; white-space: nowrap; }
        .reference { font-weight: bold; margin-bottom: 20px; }
        .read { margin: 2px 0; }
        .read-label { display: inline-block; width: 150px; font-size: 0.9em; }
        .read-info { font-size: 0.8em; color: #555; margin-left: 10px; }
        .base-A { background-color: #ffcccc; color: red; }
        .base-C { background-color: #ccffcc; color: green; }
        .base-G { background-color: #ccccff; color: blue; }
        .base-T { background-color: #ffffcc; color: #b0b000; }
        .base-gap { background-color: #eeeeee; color: gray; }
        .position-markers { font-size: 0.8em; color: #888; margin-bottom: 5px; }
      </style>
    </head>
    <body>
      <h1>Reads Alignment Visualization</h1>
      <div class="container">
        <div class="position-markers">#{generate_position_markers(String.length(ref_seq))}</div>
        <div class="reference"><span class="read-label">Reference:</span> #{colorize_sequence(ref_seq)}</div>
    """

    html_reads = reads
                 |> Enum.map(fn read ->
                   "<div class=\"read\">
                     <span class=\"read-label\">#{read.qname} (#{read.position}):</span>
                     #{colorize_sequence(read.sequence)}
                     <span class=\"read-info\">CIGAR: #{read.cigar}</span>
                   </div>"
                 end)
                 |> Enum.join("\n        ")

    html_footer = """
        #{html_reads}
      </div>
    </body>
    </html>
    """

    html_header <> html_footer
  end

  @doc """
  Generate position markers for the alignment (every 10 bases)
  """
  defp generate_position_markers(length) do
    # Create position markers every 10 bases
    0..length
    |> Enum.filter(fn pos -> rem(pos, 10) == 0 end)
    |> Enum.map(fn pos ->
      # Calculate spaces needed before the position number
      spaces = if pos == 0, do: "", else: String.duplicate(" ", 10 - String.length("#{pos}"))
      width = if pos == 0, do: 150, else: 10
      label = if pos == 0, do: "", else: spaces <> "#{pos}"
      "<span style=\"display:inline-block;width:#{width}px;\">#{label}</span>"
    end)
    |> Enum.join("")
  end

  @doc """
  Process the alignments to get reads aligned to the reference sequence.
  Only processes forward reads (not reverse-complemented).
  """
  defp process_alignments(alignments, ref_seq) do
    alignments
    |> Enum.map(fn record ->
      pos = record.pos
      seq = record.seq

      # Parse the CIGAR string to get operations
      cigar_ops = SamParser.parse_cigar(record.cigar)

      # Apply CIGAR operations to align the sequence properly
      aligned_seq = apply_cigar(seq, cigar_ops, pos, String.length(ref_seq))

      # Add metadata for visualization
      %{
        position: pos,
        sequence: aligned_seq,
        qname: record.qname,
        cigar: record.cigar
      }
    end)
  end

  @doc """
  Apply CIGAR operations to correctly position the sequence on the reference.
  CIGAR operations:
    M - alignment match (can be a sequence match or mismatch)
    I - insertion to the reference
    D - deletion from the reference
    N - skipped region from the reference
    S - soft clipping (clipped sequences present in SEQ)
    H - hard clipping (clipped sequences NOT present in SEQ)
    P - padding (silent deletion from padded reference)
    = - sequence match
    X - sequence mismatch
  """
  defp apply_cigar(seq, cigar_ops, pos, ref_length) do
    # Initialize the aligned sequence with gaps before the start position
    padded_start = String.duplicate("-", pos - 1)

    # Process the sequence according to CIGAR operations
    {aligned_seq, _seq_pos} =
      Enum.reduce(cigar_ops, {[], 0}, fn {op_length, op_type}, {result, seq_pos} ->
        case op_type do
          # For matches/mismatches, add the corresponding nucleotides from the sequence
          op when op in ["M", "=", "X"] ->
            seq_part = String.slice(seq, seq_pos, op_length)
            {result ++ String.graphemes(seq_part), seq_pos + op_length}

          # For insertions, we skip them in visualization as they can't be shown in a 1-to-1 alignment
          "I" ->
            {result, seq_pos + op_length}

          # For deletions, add gap characters
          "D" ->
            {result ++ List.duplicate("-", op_length), seq_pos}

          # For skipped regions (introns), add gap characters
          "N" ->
            {result ++ List.duplicate("-", op_length), seq_pos}

          # For soft clipping, ignore these nucleotides in the alignment
          "S" ->
            {result, seq_pos + op_length}

          # For hard clipping, these bases aren't in the sequence, so just move on
          "H" ->
            {result, seq_pos}

          # For padding, add gap characters
          "P" ->
            {result ++ List.duplicate("-", op_length), seq_pos}

          # Default case for any unrecognized operations
          _ ->
            {result, seq_pos}
        end
      end)

    # Convert the result list back to a string
    aligned_seq_str = Enum.join(aligned_seq, "")

    # Combine the padding and aligned sequence
    full_seq = padded_start <> aligned_seq_str

    # Ensure the sequence doesn't exceed reference length and pad if shorter
    cond do
      String.length(full_seq) > ref_length ->
        String.slice(full_seq, 0, ref_length)
      String.length(full_seq) < ref_length ->
        full_seq <> String.duplicate("-", ref_length - String.length(full_seq))
      true ->
        full_seq
    end
  end

  @doc """
  Colorize each nucleotide in the sequence with HTML span tags.
  """
  defp colorize_sequence(sequence) do
    sequence
    |> String.graphemes()
    |> Enum.map(fn base ->
      case base do
        "A" -> "<span class=\"base-A\">A</span>"
        "C" -> "<span class=\"base-C\">C</span>"
        "G" -> "<span class=\"base-G\">G</span>"
        "T" -> "<span class=\"base-T\">T</span>"
        "-" -> "<span class=\"base-gap\">-</span>"
        other -> "<span>#{other}</span>"
      end
    end)
    |> Enum.join("")
  end

  @doc """
  Entry point for command line interface.
  """
  def run(args) do
    {opts, args, _} = OptionParser.parse(args,
      strict: [output: :string],
      aliases: [o: :output]
    )

    output = opts[:output] || "output.html"

    case args do
      [sam_path, ref_path] ->
        case main(sam_path, ref_path, output) do
          {:ok, path} ->
            IO.puts("HTML visualization successfully generated at: #{path}")
            :ok
          {:error, reason} ->
            IO.puts("Error: #{reason}")
            :error
        end
      _ ->
        IO.puts("Usage: mix run -e 'ReadsMap.run(System.argv())' -- [SAM/BAM file] [Reference FASTA] [-o output.html]")
        :error
    end
  end
end
