package com.typeobject.wheeler.tools;

import static org.junit.jupiter.api.Assertions.assertEquals;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.List;
import java.util.regex.Pattern;
import org.junit.jupiter.api.Test;

/** Enforces the small, high-signal part of Wheeler's documentation voice. */
final class DocumentationStyleTest {
  private static final List<Path> FILES = List.of(
      Path.of("README.md"),
      Path.of("CONTRIBUTING.md"),
      Path.of("bootstrap/README.md"),
      Path.of("docs/README.md"),
      Path.of("wheeler-compiler/README.md"),
      Path.of("wheeler-conformance/README.md"),
      Path.of("wheeler-examples/README.md"));
  private static final Pattern FILLER = Pattern.compile(
      "\\b(?:let(?:'|’)s explore|delve|cutting-edge|unparalleled|game-changer|seamless|"
          + "it is important to note|it is worth noting)\\b",
      Pattern.CASE_INSENSITIVE);
  private static final Pattern PASSIVE_BY = Pattern.compile(
      "\\b(?:is|are|was|were|be|been|being)\\s+"
          + "(?:[a-z]+ed|built|bound|read|written|known|shown|given|made|set|kept|left|"
          + "sent|run|held|found|done)\\s+by\\b",
      Pattern.CASE_INSENSITIVE);

  @Test
  void reportsMechanicalStyleFailuresWithoutReadingCodeExamples() {
    List<String> diagnostics = new ArrayList<>();
    check(
        Path.of("Bad.md"),
        "The tool was built by magic; let's explore it — slowly.\n"
            + "```wheeler\nvalue; // code keeps its syntax — yes\n```\n",
        diagnostics);

    assertEquals(
        List.of(
            "Bad.md:1: WSTYLE001 replace the prose semicolon",
            "Bad.md:1: WSTYLE002 replace the prose dash",
            "Bad.md:1: WSTYLE003 remove filler language",
            "Bad.md:1: WSTYLE004 name the actor first"),
        diagnostics);
  }

  @Test
  void maintainedDocumentationUsesDirectProse() throws Exception {
    List<Path> files = new ArrayList<>(FILES);
    for (Path root : List.of(Path.of("docs/public"), Path.of("docs/internal"))) {
      try (var paths = Files.walk(root)) {
        files.addAll(paths.filter(path -> path.toString().endsWith(".md")
            || path.toString().endsWith(".mdx")).toList());
      }
    }
    files.sort(Path::compareTo);

    List<String> diagnostics = new ArrayList<>();
    for (Path file : files) {
      check(file, Files.readString(file), diagnostics);
    }
    assertEquals(List.of(), diagnostics);
  }

  private static void check(Path file, String source, List<String> diagnostics) {
    boolean fence = false;
    String[] lines = source.split("\\R", -1);
    for (int index = 0; index < lines.length; index++) {
      String line = lines[index];
      if (line.stripLeading().startsWith("```")) {
        fence = !fence;
        continue;
      }
      if (fence) {
        continue;
      }
      String prose = proseOnly(line);
      if (prose.indexOf(';') >= 0) {
        diagnostics.add(diagnostic(file, index, "WSTYLE001", "replace the prose semicolon"));
      }
      if (prose.indexOf('—') >= 0 || prose.indexOf('–') >= 0) {
        diagnostics.add(diagnostic(file, index, "WSTYLE002", "replace the prose dash"));
      }
      if (FILLER.matcher(prose).find()) {
        diagnostics.add(diagnostic(file, index, "WSTYLE003", "remove filler language"));
      }
      if (PASSIVE_BY.matcher(prose).find()) {
        diagnostics.add(diagnostic(file, index, "WSTYLE004", "name the actor first"));
      }
    }
  }

  private static String proseOnly(String line) {
    StringBuilder result = new StringBuilder(line.length());
    boolean code = false;
    for (int index = 0; index < line.length(); index++) {
      char scalar = line.charAt(index);
      if (scalar == '`') {
        code = !code;
      } else if (!code) {
        result.append(scalar);
      }
    }
    return result.toString();
  }

  private static String diagnostic(
      Path file, int zeroBasedLine, String code, String message) {
    return file + ":" + (zeroBasedLine + 1) + ": " + code + " " + message;
  }
}
