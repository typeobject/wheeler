//! Verifies and identifies one canonical bootstrap compiler-limits manifest.

module wheeler.conformance.bootstrap.compiler_limits_identity;

import wheeler.conformance.bootstrap.syntax;
import wheeler.crypto.content_identity;

classical class NativeCompilerLimitsIdentity {
  state long limitCount = 0;
  state long published = 0;

  private record ParsedLimit(long cursor, long value) {}

  private long writeHeader(borrow mut bytes expected) {
    writeAscii(expected, 0, "schema: 1");
    setByte(expected, 9, 10);
    writeAscii(expected, 10, "limits:");
    setByte(expected, 17, 10);
    return 18;
  }

  private ParsedLimit parseLimit(
    borrow byteview source,
    long cursor,
    borrow mut bytes expected,
    long prefixLength
  ) {
    cursor = consumeMetadata(source, cursor, expected, prefixLength);
    long digitStart = cursor;
    long value = 0;
    while (cursor < bufferLength(source)) limit 10 {
      long scalar = source[cursor];
      if (47 < scalar) {
        if (scalar < 58) {
          value = value * 10 + scalar - 48;
          cursor += 1;
        } else {
          break;
        }
      } else {
        break;
      }
    }

    requireMetadata(digitStart < cursor, source);
    if (source[digitStart] == 48) {
      requireMetadata(false, source);
    }

    requireMetadata(0 < value, source);
    requireMetadata(value < 1073741825, source);
    setByte(expected, 0, 10);
    cursor = consumeMetadata(source, cursor, expected, 1);
    return new ParsedLimit(cursor, value);
  }

  /// Publishes SHA-256 only for exact canonical schema-1 limits.
  ///
  /// - Effects: Mutates fixture state and caller-owned identity output.
  entry void main(borrow byteview source, borrow mut bytes identity) {
    requireMetadata(bufferLength(source) < 513, source);
    requireMetadata(31 < bufferLength(identity), source);
    region arena = new region(1400, 6);
    bytes expected = allocateBytes(arena, 64);
    long headerLength = writeHeader(expected);
    long cursor = consumeMetadata(source, 0, expected, headerLength);

    writeAscii(expected, 0, "  source-bytes: ");
    ParsedLimit sourceBytes = parseLimit(source, cursor, expected, 16);
    cursor = sourceBytes.cursor;
    writeAscii(expected, 0, "  tokens: ");
    ParsedLimit tokens = parseLimit(source, cursor, expected, 10);
    cursor = tokens.cursor;
    writeAscii(expected, 0, "  nesting: ");
    ParsedLimit nesting = parseLimit(source, cursor, expected, 11);
    cursor = nesting.cursor;
    writeAscii(expected, 0, "  declarations: ");
    ParsedLimit declarations = parseLimit(source, cursor, expected, 16);
    cursor = declarations.cursor;
    writeAscii(expected, 0, "  symbols: ");
    ParsedLimit symbols = parseLimit(source, cursor, expected, 11);
    cursor = symbols.cursor;
    writeAscii(expected, 0, "  instructions: ");
    ParsedLimit instructions = parseLimit(source, cursor, expected, 16);
    cursor = instructions.cursor;
    writeAscii(expected, 0, "  diagnostics: ");
    ParsedLimit diagnostics = parseLimit(source, cursor, expected, 15);
    cursor = diagnostics.cursor;
    writeAscii(expected, 0, "  heap-bytes: ");
    ParsedLimit heapBytes = parseLimit(source, cursor, expected, 14);
    cursor = heapBytes.cursor;
    writeAscii(expected, 0, "  stack-depth: ");
    ParsedLimit stackDepth = parseLimit(source, cursor, expected, 15);
    cursor = stackDepth.cursor;
    writeAscii(expected, 0, "  steps: ");
    ParsedLimit steps = parseLimit(source, cursor, expected, 9);
    cursor = steps.cursor;
    requireMetadata(cursor == bufferLength(source), source);

    publishSha256(source, identity, arena);
    limitCount = 10;
    published = 1;
    setOutputLength(identity, 32);
    drop(expected);
    drop(arena);
  }
}
