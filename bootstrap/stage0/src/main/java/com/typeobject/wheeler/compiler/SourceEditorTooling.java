package com.typeobject.wheeler.compiler;

import java.nio.charset.StandardCharsets;
import java.util.List;

/** Editor coordinates and edits derived from the shared source-tooling boundary. */
public final class SourceEditorTooling {
  /** Zero-based line and UTF-16 character coordinate. */
  public record Position(int line, int character) {
    public Position {
      if (line < 0 || character < 0) {
        throw new IllegalArgumentException("Invalid editor position");
      }
    }
  }

  /** Half-open source range in editor coordinates. */
  public record Range(Position start, Position end) {
    public Range {
      if (start == null || end == null
          || start.line() > end.line()
          || (start.line() == end.line() && start.character() > end.character())) {
        throw new IllegalArgumentException("Invalid editor range");
      }
    }
  }

  /** One scalar-aligned replacement for an in-memory editor document. */
  public record TextEdit(Range range, String replacement) {
    public TextEdit {
      if (range == null || replacement == null) {
        throw new IllegalArgumentException("Invalid editor text edit");
      }
    }
  }

  /** One documentation diagnostic at its parser-owned source position. */
  public record Diagnostic(String code, Range range, String message) {
    public Diagnostic {
      if (code == null || range == null || message == null) {
        throw new IllegalArgumentException("Invalid editor diagnostic");
      }
    }
  }

  private SourceEditorTooling() {}

  /** Returns the only editor edit needed to apply canonical formatting. */
  public static TextEdit format(byte[] input) {
    byte[] original = input.clone();
    SourceTooling.FormatResult formatted = SourceTooling.format(original);
    String originalText = new String(original, StandardCharsets.UTF_8);
    String formattedText = new String(formatted.source(), StandardCharsets.UTF_8);
    return scalarEdit(originalText, formattedText);
  }

  /** Returns documentation diagnostics in zero-based editor coordinates. */
  public static List<Diagnostic> checkDocumentation(byte[] input) {
    byte[] source = input.clone();
    SourceDocumentation.Analysis analysis = SourceTooling.checkDocumentation(source);
    String text = new String(source, StandardCharsets.UTF_8);
    return analysis.diagnostics().stream()
        .map(diagnostic -> {
          Position position = positionAt(text, diagnostic.characterOffset());
          return new Diagnostic(
              diagnostic.code(), new Range(position, position), diagnostic.message());
        })
        .toList();
  }

  private static TextEdit scalarEdit(String input, String output) {
    int start = commonPrefix(input, output);
    int inputEnd = input.length();
    int outputEnd = output.length();
    while (inputEnd > start && outputEnd > start) {
      int inputScalar = input.codePointBefore(inputEnd);
      int outputScalar = output.codePointBefore(outputEnd);
      if (inputScalar != outputScalar) {
        break;
      }
      int width = Character.charCount(inputScalar);
      if (inputEnd - width < start || outputEnd - width < start) {
        break;
      }
      inputEnd -= width;
      outputEnd -= width;
    }

    if (insideCrLf(input, start)) {
      start--;
    }
    if (insideCrLf(input, inputEnd)) {
      inputEnd++;
      outputEnd++;
    }

    String replacement = output.substring(start, outputEnd);
    String rebuilt = input.substring(0, start) + replacement + input.substring(inputEnd);
    if (!rebuilt.equals(output)) {
      throw new IllegalStateException("Editor edit does not reconstruct formatted source");
    }
    return new TextEdit(
        new Range(positionAt(input, start), positionAt(input, inputEnd)), replacement);
  }

  private static int commonPrefix(String left, String right) {
    int result = 0;
    while (result < left.length() && result < right.length()) {
      int leftScalar = left.codePointAt(result);
      int rightScalar = right.codePointAt(result);
      if (leftScalar != rightScalar) {
        break;
      }
      result += Character.charCount(leftScalar);
    }
    return result;
  }

  private static boolean insideCrLf(String text, int offset) {
    return 0 < offset && offset < text.length()
        && text.charAt(offset - 1) == '\r' && text.charAt(offset) == '\n';
  }

  private static Position positionAt(String text, int offset) {
    if (offset < 0 || offset > text.length()) {
      throw new IllegalArgumentException("Editor position exceeds source");
    }
    int line = 0;
    int character = 0;
    for (int index = 0; index < offset; index++) {
      char value = text.charAt(index);
      if (value == '\r') {
        if (index + 1 < offset && text.charAt(index + 1) == '\n') {
          index++;
        }
        line++;
        character = 0;
      } else if (value == '\n') {
        line++;
        character = 0;
      } else {
        character++;
      }
    }
    return new Position(line, character);
  }
}
