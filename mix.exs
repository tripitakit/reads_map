defmodule ReadsMap.MixProject do
  use Mix.Project

  def project do
    [
      app: :reads_map,
      version: "0.1.0",
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      escript: escript()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Escript configuration for CLI application
  defp escript do
    [
      main_module: ReadsMap.CLI,
      name: "reads_map",
      comment: "ReadsMap - SAM/BAM to HTML/TXT alignment visualization"
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:sam_parser, git: "https://github.com/tripitakit/sam_parser.git"}
    ]
  end
end
