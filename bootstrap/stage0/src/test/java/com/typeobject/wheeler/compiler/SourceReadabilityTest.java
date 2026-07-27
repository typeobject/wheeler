package com.typeobject.wheeler.compiler;

import static org.junit.jupiter.api.Assertions.assertEquals;

import java.nio.file.Files;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.List;
import java.util.regex.Pattern;
import org.junit.jupiter.api.Test;

/** High-signal source readability checks analogous to Error Prone bug patterns. */
class SourceReadabilityTest {
  private static final Pattern ENDIAN_WRITE = Pattern.compile(
      "write(?:Unsigned|Signed)LittleEndian\\(([^()]*)\\)", Pattern.DOTALL);
  private static final Pattern LABELED_INTEGER = Pattern.compile(
      "/\\* [a-z][A-Za-z0-9]*= \\*/\\s*-?[0-9]+");
  private static final Pattern INTEGER = Pattern.compile("-?[0-9]+");

  @Test
  void reportsOnlyUnlabeledAdjacentEndianLiterals() {
    List<String> diagnostics = new ArrayList<>();
    check(
        Path.of("Broken.w"),
        "cursor = writeUnsignedLittleEndian(output, cursor, 0, 8);\n",
        diagnostics);
    assertEquals(
        List.of("Broken.w:1: WREAD001 adjacent endian literals require value and width labels"),
        diagnostics);

    diagnostics.clear();
    check(
        Path.of("Clear.w"),
        "cursor = writeUnsignedLittleEndian("
            + "output, cursor, /* value= */ 0, /* width= */ 8);\n",
        diagnostics);
    check(
        Path.of("Computed.w"),
        "cursor = writeUnsignedLittleEndian(output, cursor, value, 8);\n",
        diagnostics);
    assertEquals(List.of(), diagnostics);
  }

  @Test
  void adjacentEndianValueAndWidthLiteralsCarryCanonicalLabels() throws Exception {
    Path root = Path.of("../wheeler-compiler/src/main/wheeler");
    List<String> diagnostics = new ArrayList<>();
    try (var paths = Files.walk(root)) {
      for (Path source : paths.filter(path -> path.toString().endsWith(".w")).sorted().toList()) {
        check(source, Files.readString(source), diagnostics);
      }
    }

    assertEquals(List.of(), diagnostics);
  }

  private static void check(Path source, String text, List<String> diagnostics) {
    var calls = ENDIAN_WRITE.matcher(text);
    while (calls.find()) {
      String[] arguments = calls.group(1).split(",", -1);
      if (arguments.length != 4) {
        continue;
      }
      String value = arguments[2].trim();
      String width = arguments[3].trim();
      if (!integerArgument(value) || !integerArgument(width)) {
        continue;
      }
      if (!value.matches("/\\* value= \\*/\\s*-?[0-9]+")
          || !width.matches("/\\* width= \\*/\\s*-?[0-9]+")) {
        int line = 1 + text.substring(0, calls.start()).replaceAll("[^\\n]", "").length();
        diagnostics.add(source + ":" + line
            + ": WREAD001 adjacent endian literals require value and width labels");
      }
    }
  }

  private static boolean integerArgument(String argument) {
    if (INTEGER.matcher(argument).matches()) {
      return true;
    }
    return LABELED_INTEGER.matcher(argument).matches();
  }
}
