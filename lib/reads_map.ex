defmodule ReadsMap do
  @moduledoc """
  ReadsMap generates visualizations of reads aligned to a reference sequence.
  It takes a SAM/BAM file and a FASTA reference file as input and can produce
  either HTML or text output formats.
  """

  alias ReadsMap.RenderHTML
  alias ReadsMap.RenderTxt

  @doc """
  Main function that processes the SAM/BAM file and FASTA reference to produce a visualization.

  ## Parameters

    * `sam_path` - Path to the SAM/BAM file
    * `ref_path` - Path to the FASTA reference file
    * `output_path` - Path to save the output file (optional, defaults to "output.html" or "output.txt")
    * `format` - Output format, either :html or :txt (optional, defaults to :html)

  ## Returns

    * `{:ok, output_path}` - If the visualization was successfully generated
    * `{:error, reason}` - If there was an error processing the files
  """
  def main(sam_path, ref_path, output_path \\ nil, format \\ :html) do
    # Set default output path based on format if not provided
    output_path = output_path || case format do
      :html -> "output.html"
      :txt -> "output.txt"
      _ -> "output.html"
    end

    with {:ok, reference} <- load_reference(ref_path),
         {:ok, alignments} <- load_alignments(sam_path) do

      # Filter out reverse reads
      forward_alignments = Enum.filter(alignments, fn aln -> not SamParser.is_reverse?(aln) end)

      # Process alignments to get properly formatted reads
      reads = process_alignments(forward_alignments, reference)

      # Generate output based on format
      content = case format do
        :html -> RenderHTML.generate_html(reference, reads)
        :txt -> RenderTxt.generate_txt(reference, reads, sam_path, ref_path)
        _ -> RenderHTML.generate_html(reference, reads)
      end

      case File.write(output_path, content) do
        :ok -> {:ok, output_path}
        {:error, reason} -> {:error, "Failed to write output file: #{reason}"}
      end
    end
  end

  defp load_reference(ref_path) do
    try do
      [first_seq | _] = BioElixir.SeqIO.read_fasta_file(ref_path)
      %{display_id: _id, seq: seq} = first_seq
      {:ok, seq}
    rescue
      e -> {:error, "Failed to parse reference file: #{inspect(e)}"}
    end
  end

  defp load_alignments(sam_path) do
    try do
      sam = SamParser.parse_file(sam_path)
      {:ok, sam.alignments}
    rescue
      e -> {:error, "Failed to parse SAM/BAM file: #{inspect(e)}"}
    end
  end

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
  Entry point for command line interface.
  """
  def run(args) do
    {opts, args, _} = OptionParser.parse(args,
      strict: [output: :string, format: :string],
      aliases: [o: :output, f: :format]
    )

    # Get format from options, default to html
    format = case opts[:format] do
      "txt" -> :txt
      "text" -> :txt
      "html" -> :html
      _ -> :html
    end

    # Set default output based on format if not provided
    output = opts[:output] || case format do
      :html -> "output.html"
      :txt -> "output.txt"
    end

    case args do
      [sam_path, ref_path] ->
        case main(sam_path, ref_path, output, format) do
          {:ok, path} ->
            IO.puts("#{String.upcase(to_string(format))} visualization successfully generated at: #{path}")
            :ok
          {:error, reason} ->
            IO.puts("Error: #{reason}")
            :error
        end
      _ ->
        IO.puts("""
        Usage: mix run -e 'ReadsMap.run(System.argv())' -- [SAM/BAM file] [Reference FASTA] [options]

        Options:
          -o, --output PATH   Path to save output (default: "output.html" or "output.txt")
          -f, --format TYPE   Output format: "html" or "txt" (default: "html")
        """)
        :error
    end
  end
end
