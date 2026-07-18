package com.typeobject.wheeler.tools;

import com.typeobject.wheeler.compiler.SourceDocumentation;
import java.io.InputStream;
import java.io.PrintStream;
import java.util.Arrays;
import java.util.List;

/** Read-only deterministic source documentation command. */
final class DocumentationCommand {
  private DocumentationCommand() {}

  static int execute(
      String[] args,
      InputStream input,
      PrintStream out,
      PrintStream error) throws Exception {
    if (args.length == 2 && args[1].equals("--stdin")) {
      return check("<stdin>", SourceCommandInputs.readStdin(input, "Documentation"), out);
    }
    if (args.length < 2 || Arrays.stream(args, 1, args.length)
        .anyMatch(argument -> argument.startsWith("--"))) {
      return usage(error);
    }
    List<SourceCommandInputs.SourceFile> sources = SourceCommandInputs.collect(
        Arrays.asList(args).subList(1, args.length), "Documentation");
    int diagnostics = 0;
    for (SourceCommandInputs.SourceFile source : sources) {
      diagnostics += check(source.path().toString(), source.text(), out);
    }
    return diagnostics == 0 ? 0 : 1;
  }

  private static int check(String path, String source, PrintStream out) {
    List<SourceDocumentation.Diagnostic> diagnostics = SourceDocumentation.checkFile(source);
    diagnostics.forEach(diagnostic -> out.println(
        diagnostic.code() + " " + path + ":" + diagnostic.line() + ":"
            + diagnostic.column() + " " + diagnostic.message()));
    return diagnostics.size();
  }

  private static int usage(PrintStream error) {
    error.println("Usage: wheeler check-docs <file-or-directory>... | --stdin");
    return 2;
  }
}
