package com.typeobject.wheeler.packageformat;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.HexFormat;

/** Complete deterministic resource ceilings for one bootstrap compilation. */
public record BootstrapCompilerLimits(
    int sourceBytes,
    int tokens,
    int nesting,
    int declarations,
    int symbols,
    int instructions,
    int diagnostics,
    int heapBytes,
    int stackDepth,
    int steps) {
  public static final int SCHEMA_VERSION = 1;
  public static final String FILE_NAME = "wheeler.compiler-limits.yaml";
  private static final int MAX_LIMIT = 1_073_741_824;

  public BootstrapCompilerLimits {
    positive(sourceBytes, "source bytes");
    positive(tokens, "tokens");
    positive(nesting, "nesting");
    positive(declarations, "declarations");
    positive(symbols, "symbols");
    positive(instructions, "instructions");
    positive(diagnostics, "diagnostics");
    positive(heapBytes, "heap bytes");
    positive(stackDepth, "stack depth");
    positive(steps, "steps");
  }

  public String canonicalText() {
    return "schema: " + SCHEMA_VERSION + "\n"
        + "limits:\n"
        + field("source-bytes", sourceBytes)
        + field("tokens", tokens)
        + field("nesting", nesting)
        + field("declarations", declarations)
        + field("symbols", symbols)
        + field("instructions", instructions)
        + field("diagnostics", diagnostics)
        + field("heap-bytes", heapBytes)
        + field("stack-depth", stackDepth)
        + field("steps", steps);
  }

  public byte[] canonicalBytes() {
    return canonicalText().getBytes(StandardCharsets.UTF_8);
  }

  public String identity() {
    try {
      return HexFormat.of().formatHex(
          MessageDigest.getInstance("SHA-256").digest(canonicalBytes()));
    } catch (NoSuchAlgorithmException exception) {
      throw new IllegalStateException("SHA-256 is unavailable", exception);
    }
  }

  private static String field(String name, int value) {
    return "  " + name + ": " + value + "\n";
  }

  private static void positive(int value, String description) {
    if (value <= 0 || value > MAX_LIMIT) {
      throw new PackageFormatException("Invalid bootstrap limit for " + description);
    }
  }
}
