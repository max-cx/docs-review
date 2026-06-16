# Instructions for a Vale review

Violations of style rules are reported by the Vale linter tool.
Follow the specific instructions how to properly run this tool:

  1. Check if `vale` command is installed. If the `vale` command is not installed, abort and ask the user to install Vale.
  2. Read and execute the section # Instructions about the Review Report File.
  3. On the content that the user has specified in the prompt, update `vale`, run the `vale --output line` command, analyze its output, and ignore false positives.
  4. Read https://raw.githubusercontent.com/jhradilek/asciidoctor-dita-vale/refs/heads/main/README.md
  5. You must review every sentence of the entered text separately, sentence by sentence for violations of all rules (issues) in the sentence.
  6. Append the results to the review report file.
