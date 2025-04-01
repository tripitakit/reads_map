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

  defp generate_position_markers(length) do
    # Create position markers every 10 bases
    0..length
    |> Enum.filter(fn pos -> rem(pos, 10) == 0 and pos > 0 end)
    |> Enum.map(fn pos ->
      "<span style=\"display:inline-block;width:#{10*8}px;text-align:center;\">#{pos}</span>"
    end)
    |> Enum.join("")
  end

  defp colorize_sequence(sequence) do
    sequence
    |> String.graphemes()
    |> Enum.map(fn base ->
      case base do
        "A" -> "<span class=\"base base-A\">A</span>"
        "C" -> "<span class=\"base base-C\">C</span>"
        "G" -> "<span class=\"base base-G\">G</span>"
        "T" -> "<span class=\"base base-T\">T</span>"
        "-" -> "<span class=\"base base-gap\">-</span>"
        other -> "<span class=\"base\">#{other}</span>"
      end
    end)
    |> Enum.join("")
  end

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
        body {
          font-family: monospace;
          margin: 0;
          padding: 0;
          height: 100vh;
          display: flex;
          flex-direction: column;
          overflow: hidden;
        }

        .page-header {
          padding: 10px 15px;
          background-color: #f5f5f5;
          box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }

        .page-title {
          margin-top: 0;
          margin-bottom: 10px;
          font-size: 1.5em;
        }

        .controls {
          margin-bottom: 10px;
          font-size: 0.9em;
        }

        .main-container {
          display: flex;
          flex-direction: column;
          height: calc(100vh - 100px);
          border: 1px solid #ccc;
        }

        .labels-column {
          position: sticky;
          left: 0;
          min-width: 300px;
          max-width: 300px;
          background-color: white;
          border-right: 1px solid #eee;
          z-index: 5;
        }

        /* Container with virtual scrolling capabilities */
        .reads-container {
          flex-grow: 1;
          overflow: auto;
          position: relative;
          display: flex;
          flex-direction: column;
          will-change: transform; /* Performance hint for browsers */
        }

        .horizontal-layout {
          display: flex;
          min-width: max-content;
          contain: content; /* Performance optimization */
        }

        .reference-section {
          position: sticky;
          top: 0;
          background-color: white;
          z-index: 10;
          border-bottom: 2px solid #ddd;
        }

        .sequences-column {
          flex: 1;
        }

        /* Use CSS containment for better performance */
        .virtual-scroller {
          height: 100%;
          overflow: auto;
          contain: strict;
          content-visibility: auto; /* Modern browsers only render visible content */
        }

        .read-row {
          display: flex;
          contain: content;
        }

        .read-label, .position-cell, .reference-label {
          height: 20px;
          line-height: 20px;
          padding: 1px 5px;
          white-space: nowrap;
          overflow: hidden;
          text-overflow: ellipsis;
          font-size: 0.85em;
          contain: content; /* Optimize layout calculations */
        }

        .position-row {
          height: 18px;
          font-size: 0.75em;
          color: #777;
          white-space: nowrap;
          contain: content;
        }

        .read-label {
          min-width: 290px;
          max-width: 290px;
          font-size: 0.85em;
        }

        .reference-label {
          font-weight: bold;
          font-size: 0.85em;
        }

        .read-sequence {
          white-space: nowrap;
          font-size: 0.85em;
          contain: content; /* Optimize layout calculations */
        }

        .reference-sequence {
          font-weight: bold;
          white-space: nowrap;
          font-size: 0.85em;
        }

        .read-info {
          font-size: 0.75em;
          color: #555;
          margin-left: 10px;
        }

        /* Optimize rendering of colored bases */
        .base {
          display: inline-block;
          width: 8px;
          text-align: center;
        }
        .base-A { background-color: #ffcccc; color: red; }
        .base-C { background-color: #ccffcc; color: green; }
        .base-G { background-color: #ccccff; color: blue; }
        .base-T { background-color: #ffffcc; color: #b0b000; }
        .base-gap { background-color: #eeeeee; color: gray; }

        .reads-container::-webkit-scrollbar {
          width: 10px;
          height: 10px;
        }

        .reads-container::-webkit-scrollbar-thumb {
          background-color: #888;
          border-radius: 5px;
        }

        .reads-container::-webkit-scrollbar-track {
          background-color: #f1f1f1;
        }

        .read-label {
          position: relative;
        }

        .read-label:hover::after {
          content: attr(title);
          position: absolute;
          left: 0;
          top: 100%;
          z-index: 20;
          background-color: #333;
          color: #fff;
          padding: 5px;
          border-radius: 3px;
          white-space: nowrap;
          font-size: 12px;
          box-shadow: 0 2px 5px rgba(0,0,0,0.2);
        }

        /* Loading and status indicators */
        .loading-indicator {
          position: fixed;
          top: 50%;
          left: 50%;
          transform: translate(-50%, -50%);
          background: rgba(255, 255, 255, 0.9);
          padding: 20px;
          border-radius: 10px;
          box-shadow: 0 0 10px rgba(0, 0, 0, 0.2);
          z-index: 100;
          display: none;
        }

        .visible {
          display: block;
        }

        .status-bar {
          position: fixed;
          bottom: 0;
          left: 0;
          right: 0;
          padding: 5px 10px;
          background: #f5f5f5;
          border-top: 1px solid #ddd;
          font-size: 12px;
          display: flex;
          justify-content: space-between;
        }
      </style>
      <script>
        // Store references to DOM elements we'll use frequently
        let container, posInput, virtualScroller;
        let visibleReads = new Set();
        let loadingIndicator;
        let statusElement;

        // Optimization settings
        const BUFFER_SIZE = 50; // Number of reads to render above/below visible area
        const RENDER_DEBOUNCE = 100; // ms to wait before rendering after scroll
        let renderTimeout = null;
        let lastScrollPos = { top: 0, left: 0 };
        let loadTime = 0;
        let readCount = 0;

        document.addEventListener('DOMContentLoaded', function() {
          // Initialize UI references
          container = document.querySelector('.reads-container');
          posInput = document.getElementById('position-input');
          loadingIndicator = document.getElementById('loading-indicator');
          statusElement = document.getElementById('status-info');

          // Capture load time
          loadTime = performance.now();

          // Initialize position field
          posInput.value = 1;

          // Initial rendering
          updateVisibleReads();

          // Update status bar
          readCount = document.querySelectorAll('.read-row').length;
          updateStatus();

          // Optimize scroll performance with debounced rendering
          container.addEventListener('scroll', function() {
            // Always update position for smooth feel
            const approxPos = Math.round(this.scrollLeft / 8) + 1;
            if (approxPos > 0) {
              posInput.value = approxPos;
            }

            // Store scroll position
            lastScrollPos = {
              top: this.scrollTop,
              left: this.scrollLeft
            };

            // Debounce the expensive DOM updates
            if (renderTimeout) {
              clearTimeout(renderTimeout);
            }

            renderTimeout = setTimeout(function() {
              updateVisibleReads();
              updateStatus();
            }, RENDER_DEBOUNCE);
          });
        });

        function scrollToPosition() {
          const position = document.getElementById('position-input').value;
          if (position) {
            container.scrollLeft = (position - 1) * 8;
            // Force update of visible elements
            updateVisibleReads();
          }
        }

        // Efficiently update only the visible reads
        function updateVisibleReads() {
          // Nothing to optimize if we're showing all reads already
          if (readCount <= 200) return;

          // Show loading indicator for large data sets
          if (readCount > 1000) {
            loadingIndicator.classList.add('visible');
          }

          // Calculate viewport boundaries
          const scrollTop = container.scrollTop;
          const viewportHeight = container.clientHeight;
          const viewportBottom = scrollTop + viewportHeight;

          // Process in the next animation frame for better performance
          requestAnimationFrame(() => {
            try {
              const allReads = document.querySelectorAll('.read-row');
              const readHeight = 22; // Approximate height of each read row

              // Calculate which reads should be visible (with buffer)
              const startIndex = Math.max(0, Math.floor(scrollTop / readHeight) - BUFFER_SIZE);
              const endIndex = Math.min(allReads.length, Math.ceil(viewportBottom / readHeight) + BUFFER_SIZE);

              // Track which reads we've processed
              const currentlyVisible = new Set();

              // Update visibility
              for (let i = startIndex; i < endIndex; i++) {
                const read = allReads[i];
                if (read) {
                  read.style.display = '';
                  currentlyVisible.add(i);
                }
              }

              // Hide reads that were previously visible but now aren't
              visibleReads.forEach(index => {
                if (!currentlyVisible.has(index) && index < allReads.length) {
                  allReads[index].style.display = 'none';
                }
              });

              // Update our tracking set
              visibleReads = currentlyVisible;

            } finally {
              // Always hide loading indicator when done
              loadingIndicator.classList.remove('visible');
            }
          });
        }

        function updateStatus() {
          const visibleCount = visibleReads.size;
          const loadTimeMs = Math.round(performance.now() - loadTime);

          statusElement.textContent = `Showing ${visibleCount} of ${readCount} reads • Load time: ${loadTimeMs}ms`;
        }
      </script>
    </head>
    <body>
      <div class="page-header">
        <h1 class="page-title">Reads Alignment Visualization</h1>
        <div class="controls">
          <label for="position-input">Jump to position: </label>
          <input type="number" id="position-input" min="1" max="#{String.length(ref_seq)}" />
          <button onclick="scrollToPosition()">Go</button>
        </div>
      </div>

      <div id="loading-indicator" class="loading-indicator">Loading reads...</div>

      <div class="main-container">
        <div class="reads-container">
          <div class="horizontal-layout reference-section">
            <div class="labels-column">
              <div class="read-label reference-label">Reference:</div>
            </div>
            <div class="sequences-column">
              <div class="position-row">#{generate_position_markers(String.length(ref_seq))}</div>
              <div class="reference-sequence">#{colorize_sequence(ref_seq)}</div>
            </div>
          </div>

          <div class="horizontal-layout sequences-section">
            <div class="labels-column">
              #{generate_read_labels(reads)}
            </div>
            <div class="sequences-column">
              #{generate_read_sequences(reads)}
            </div>
          </div>
        </div>
      </div>

      <div class="status-bar">
        <span id="status-info">Loading...</span>
        <span>ReadsMap Alignment Tool</span>
      </div>
    </body>
    </html>
    """

    html_header
  end

  defp generate_read_labels(reads) do
    reads
    |> Enum.with_index()
    |> Enum.map(fn {read, index} ->
      "<div class=\"read-label\" title=\"#{read.qname} (#{read.position})\" data-index=\"#{index}\">#{read.qname} (#{read.position}):</div>"
    end)
    |> Enum.join("\n")
  end

  defp generate_read_sequences(reads) do
    reads
    |> Enum.with_index()
    |> Enum.map(fn {read, index} ->
      "<div class=\"read-row\" data-index=\"#{index}\">
        <div class=\"read-sequence\">#{colorize_sequence(read.sequence)} <span class=\"read-info\">CIGAR: #{read.cigar}</span></div>
      </div>"
    end)
    |> Enum.join("\n")
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
