defmodule ReadsMap.FastaParser do
  @moduledoc """
  A simple FASTA parser module for reading single sequence FASTA files.
  """

  @doc """
  Reads a single sequence FASTA file and returns the sequence.

  ## Parameters
    * `file_path` - Path to the FASTA file

  ## Returns
    * `{:ok, %{id: String.t(), seq: String.t()}}` - If file parsing was successful
    * `{:error, reason}` - If there was an error parsing the file

  ## Example
      iex> ReadsMap.FastaParser.read_fasta("input/reference.fasta")
      {:ok, %{id: "Reference1", seq: "ATGCATGCATGC"}}
  """
  def read_fasta(file_path) do
    try do
      case File.read(file_path) do
        {:ok, content} ->
          parse_fasta_content(content)
        {:error, reason} ->
          {:error, "Failed to read file: #{reason}"}
      end
    rescue
      e -> {:error, "Error parsing FASTA file: #{inspect(e)}"}
    end
  end

  @doc """
  Parses FASTA content and returns the first sequence found.
  """
  def parse_fasta_content(content) do
    # Split content by lines and remove empty lines
    lines = content
            |> String.split(["\r\n", "\n"])
            |> Enum.filter(&(String.trim(&1) != ""))

    # Process lines
    case parse_lines(lines) do
      {id, seq} when is_binary(seq) and seq != "" ->
        {:ok, %{id: id, seq: seq}}
      _ ->
        {:error, "Invalid FASTA format or empty sequence"}
    end
  end

  defp parse_lines(lines) do
    # Group lines into header and sequence parts
    {header, seq_lines} = Enum.split_with(lines, &String.starts_with?(&1, ">"))

    # Extract ID from the first header
    id = case header do
      [first_header | _] -> String.trim_leading(first_header, ">") |> String.split() |> List.first()
      _ -> "Unknown"
    end

    # Combine sequence lines
    seq = Enum.join(seq_lines, "")
          |> String.replace(~r/\s+/, "")  # Remove whitespace
          |> String.upcase()              # Ensure uppercase

    {id, seq}
  end
end
