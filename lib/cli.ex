defmodule ReadsMap.CLI do
  @moduledoc """
  Command-line interface for ReadsMap.

  This module serves as the entry point for the ReadsMap CLI application,
  parsing command-line arguments and delegating to the core functionality.
  """

  @doc """
  The main entry point for the escript.

  ## Parameters

    * `args` - The command-line arguments.
  """
  def main(args) do
    {opts, args, _} = OptionParser.parse(args,
      strict: [output: :string, format: :string, help: :boolean],
      aliases: [o: :output, f: :format, h: :help]
    )

    if opts[:help] do
      print_help()
    else
      process_args(args, opts)
    end
  end

  defp process_args([sam_path, ref_path], opts) do
    # Get format from options, default to txt
    format = case opts[:format] do
      "html" -> :html
      "text" -> :txt
      "txt" -> :txt
      "fasta" -> :fasta
      _ -> :txt
    end

    # Set default output based on format if not provided
    output = opts[:output] || case format do
      :html -> "output.html"
      :fasta -> "output.fasta"
      :txt -> "output.txt"
    end

    case ReadsMap.process(sam_path, ref_path, output, format) do
      {:ok, path} ->
        IO.puts("#{String.upcase(to_string(format))} visualization successfully generated at: #{path}")
        :ok
      {:error, reason} ->
        IO.puts("Error: #{reason}")
        exit({:shutdown, 1})
    end
  end

  defp process_args(_, _) do
    print_help()
    exit({:shutdown, 1})
  end

  defp print_help do
    IO.puts("""
    ReadsMap - Generate visualizations of reads aligned to a reference sequence

    Usage: reads_map [SAM/BAM file] [Reference FASTA] [options]

    Options:
      -o, --output PATH   Path to save output (default: "output.txt", "output.html", or "output.fasta")
      -f, --format TYPE   Output format: "txt", "html", or "fasta" (default: "txt")
      -h, --help          Display this help message

    Examples:
      reads_map input/sample.bam input/reference.fasta -f html -o alignment.html
      reads_map input/sample.bam input/reference.fasta -f fasta -o aligned.fasta
    """)
  end
end
