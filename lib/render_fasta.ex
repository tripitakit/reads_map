defmodule ReadsMap.RenderFasta do
  @moduledoc """
  Module responsible for rendering FASTA output for read alignments.

  Provides functions to generate FASTA format visualization of sequence alignments,
  which is useful for compatibility with other bioinformatics tools.
  """

  @line_width 60

  @doc """
  Generates a FASTA representation of the alignment.

  ## Parameters
    * `ref_seq` - The reference sequence
    * `reads` - Processed reads with alignment information
  ## Returns
    * String containing the FASTA format representation of the alignment
  """
  def generate_fasta(ref_seq, reads) do
    # Format the reference sequence
    reference_fasta = format_reference(ref_seq)

    # Format all read sequences
    reads_fasta = Enum.map(reads, &format_read/1) |> Enum.join("\n")

    # Combine all parts
    [
      reference_fasta,
      reads_fasta
    ]
    |> Enum.join("\n")
  end


  defp format_reference(ref_seq) do
    ref_seq_wrapped = wrap_sequence(ref_seq)

    [
      ">Reference",
      ref_seq_wrapped
    ]
    |> Enum.join("\n")
  end


  defp format_read(read) do
    seq_wrapped = wrap_sequence(read.sequence)

    [
      ">#{read.qname} position=#{read.position} cigar=#{read.cigar}",
      seq_wrapped
    ]
    |> Enum.join("\n")
  end


  defp wrap_sequence(seq) do
    seq
    |> String.graphemes()
    |> Enum.chunk_every(@line_width)
    |> Enum.map(&Enum.join(&1, ""))
    |> Enum.join("\n")
  end
end
