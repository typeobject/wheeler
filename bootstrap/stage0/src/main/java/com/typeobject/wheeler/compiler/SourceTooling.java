package com.typeobject.wheeler.compiler;

import java.nio.ByteBuffer;
import java.nio.charset.CharacterCodingException;
import java.nio.charset.CodingErrorAction;
import java.nio.charset.StandardCharsets;

/** Shared byte-oriented formatter and documentation boundary for commands and editors. */
public final class SourceTooling {
  /** One deterministic byte edit from the original source to its canonical form. */
  public record TextEdit(int startByte, int endByte, byte[] replacement) {
    public TextEdit {
      if (startByte < 0 || endByte < startByte || replacement == null) {
        throw new IllegalArgumentException("Invalid source text edit");
      }
      replacement = replacement.clone();
    }

    @Override
    public byte[] replacement() {
      return replacement.clone();
    }
  }

  /** Canonical source bytes and their smallest single replacement edit. */
  public record FormatResult(byte[] source, TextEdit edit) {
    public FormatResult {
      if (source == null || edit == null) {
        throw new IllegalArgumentException("Invalid source format result");
      }
      source = source.clone();
    }

    @Override
    public byte[] source() {
      return source.clone();
    }
  }

  private SourceTooling() {}

  /** Formats explicit strict UTF-8 bytes without consulting ambient host state. */
  public static FormatResult format(byte[] input) {
    byte[] original = input.clone();
    String text = decode(original);
    byte[] formatted = SourceFormatter.format(text).getBytes(StandardCharsets.UTF_8);
    return new FormatResult(formatted, minimalEdit(original, formatted));
  }

  /** Checks and extracts documentation from explicit strict UTF-8 bytes. */
  public static SourceDocumentation.Analysis checkDocumentation(byte[] input) {
    return SourceDocumentation.analyze(decode(input.clone()));
  }

  private static String decode(byte[] input) {
    try {
      return StandardCharsets.UTF_8.newDecoder()
          .onMalformedInput(CodingErrorAction.REPORT)
          .onUnmappableCharacter(CodingErrorAction.REPORT)
          .decode(ByteBuffer.wrap(input))
          .toString();
    } catch (CharacterCodingException exception) {
      throw new CompilerException(1, "source tooling input is not strict UTF-8");
    }
  }

  private static TextEdit minimalEdit(byte[] input, byte[] output) {
    int prefix = 0;
    int shared = Math.min(input.length, output.length);
    while (prefix < shared && input[prefix] == output[prefix]) {
      prefix++;
    }

    int suffix = 0;
    while (suffix < shared - prefix
        && input[input.length - suffix - 1] == output[output.length - suffix - 1]) {
      suffix++;
    }

    byte[] replacement = java.util.Arrays.copyOfRange(output, prefix, output.length - suffix);
    return new TextEdit(prefix, input.length - suffix, replacement);
  }
}
