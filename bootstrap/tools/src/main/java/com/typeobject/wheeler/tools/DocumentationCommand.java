package com.typeobject.wheeler.tools;

import com.typeobject.wheeler.compiler.SourceDocumentation;
import com.typeobject.wheeler.compiler.SourceTooling;
import java.io.InputStream;
import java.io.PrintStream;
import java.nio.charset.StandardCharsets;
import java.nio.file.Path;
import java.util.ArrayList;
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
      return check(
          "<stdin>",
          SourceCommandInputs.readStdin(input, "Documentation").getBytes(StandardCharsets.UTF_8),
          out);
    }
    if (args.length < 2) {
      return usage(error);
    }
    boolean includeTests = false;
    ArrayList<String> inputs = new ArrayList<>();
    for (String argument : Arrays.asList(args).subList(1, args.length)) {
      if (argument.equals("--include-tests")) {
        if (includeTests) {
          return usage(error);
        }
        includeTests = true;
      } else if (argument.startsWith("--")) {
        return usage(error);
      } else {
        inputs.add(argument);
      }
    }
    if (inputs.isEmpty()) {
      return usage(error);
    }
    boolean includeTestSources = includeTests;
    List<SourceCommandInputs.SourceFile> sources = SourceCommandInputs.collect(
        inputs,
        "Documentation",
        path -> includeTestSources || !isTestSource(path));
    int diagnostics = 0;
    for (SourceCommandInputs.SourceFile source : sources) {
      diagnostics += check(source.path().toString(), source.bytes(), out);
    }
    return diagnostics == 0 ? 0 : 1;
  }

  private static int check(String path, byte[] source, PrintStream out) {
    List<SourceDocumentation.Diagnostic> diagnostics =
        SourceTooling.checkDocumentation(source).diagnostics();
    diagnostics.forEach(diagnostic -> out.println(
        diagnostic.code() + " " + path + ":" + diagnostic.line() + ":"
            + diagnostic.column() + " " + diagnostic.message()));
    return diagnostics.size();
  }

  private static boolean isTestSource(Path path) {
    for (int index = 0; index + 2 < path.getNameCount(); index++) {
      if (path.getName(index).toString().equals("src")
          && path.getName(index + 1).toString().equals("test")
          && path.getName(index + 2).toString().equals("wheeler")) {
        return true;
      }
    }
    return false;
  }

  private static int usage(PrintStream error) {
    error.println(
        "Usage: wheeler check-docs [--include-tests] <file-or-directory>... | --stdin");
    return 2;
  }
}
