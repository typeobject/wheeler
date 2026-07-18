package com.typeobject.wheeler.tools;

import com.typeobject.wheeler.compiler.SourceDocumentation;
import java.io.IOException;
import java.io.InputStream;
import java.io.PrintStream;
import java.nio.ByteBuffer;
import java.nio.charset.CharacterCodingException;
import java.nio.charset.CodingErrorAction;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.LinkOption;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

/** Read-only deterministic source documentation command. */
final class DocumentationCommand {
  private static final int MAX_SOURCE_BYTES = 16 * 1024 * 1024;
  private static final int MAX_SOURCE_FILES = 65_535;

  private DocumentationCommand() {}

  static int execute(
      String[] args,
      InputStream input,
      PrintStream out,
      PrintStream error) throws Exception {
    if (args.length == 2 && args[1].equals("--stdin")) {
      return check("<stdin>", readStdin(input), out);
    }
    if (args.length < 2) {
      return usage(error);
    }
    List<Path> sources = collectSources(args);
    int diagnostics = 0;
    for (Path source : sources) {
      diagnostics += check(source.toString(), readSource(source), out);
    }
    return diagnostics == 0 ? 0 : 1;
  }

  private static List<Path> collectSources(String[] args) throws IOException {
    List<Path> result = new ArrayList<>();
    Set<Path> identities = new HashSet<>();
    for (int index = 1; index < args.length; index++) {
      Path requested = Path.of(args[index]).normalize();
      if (Files.isSymbolicLink(requested)) {
        throw new IOException("Documentation input must not be a symbolic link: " + requested);
      }
      if (Files.isRegularFile(requested, LinkOption.NOFOLLOW_LINKS)) {
        addSource(requested, identities, result);
      } else if (Files.isDirectory(requested, LinkOption.NOFOLLOW_LINKS)) {
        try (var paths = Files.walk(requested)) {
          for (Path path : paths.toList()) {
            if (Files.isSymbolicLink(path)) {
              throw new IOException("Documentation input contains a symbolic link: " + path);
            }
            if (Files.isRegularFile(path, LinkOption.NOFOLLOW_LINKS)
                && path.getFileName().toString().endsWith(".w")) {
              addSource(path.normalize(), identities, result);
            }
          }
        }
      } else {
        throw new IOException("Documentation input is not a physical file or directory: " + requested);
      }
    }
    result.sort(Comparator.comparing(Path::toString));
    return List.copyOf(result);
  }

  private static void addSource(
      Path source,
      Set<Path> identities,
      List<Path> result) throws IOException {
    if (result.size() >= MAX_SOURCE_FILES) {
      throw new IOException("Documentation input exceeds 65,535 source files");
    }
    if (!source.getFileName().toString().endsWith(".w")) {
      throw new IOException("Documentation input is not a .w source: " + source);
    }
    Path identity = source.toAbsolutePath().normalize();
    if (!identities.add(identity)) {
      throw new IOException("Duplicate documentation input: " + source);
    }
    result.add(source);
  }

  private static String readSource(Path source) throws IOException {
    long size = Files.size(source);
    if (size > MAX_SOURCE_BYTES) {
      throw new IOException("Documentation input exceeds 16 MiB: " + source);
    }
    return decode(Files.readAllBytes(source), source.toString());
  }

  private static String readStdin(InputStream input) throws IOException {
    byte[] bytes = input.readNBytes(MAX_SOURCE_BYTES + 1);
    if (bytes.length > MAX_SOURCE_BYTES) {
      throw new IOException("Documentation stdin exceeds 16 MiB");
    }
    return decode(bytes, "<stdin>");
  }

  private static String decode(byte[] bytes, String source) throws IOException {
    try {
      return StandardCharsets.UTF_8.newDecoder()
          .onMalformedInput(CodingErrorAction.REPORT)
          .onUnmappableCharacter(CodingErrorAction.REPORT)
          .decode(ByteBuffer.wrap(bytes))
          .toString();
    } catch (CharacterCodingException exception) {
      throw new IOException("Documentation input is not strict UTF-8: " + source, exception);
    }
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
