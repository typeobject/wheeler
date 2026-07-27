//! Verifies and identifies one canonical bootstrap compiler-options manifest.

module examples.bootstrap.compiler_options_identity;

import examples.bootstrap.syntax;
import wheeler.crypto.content_identity;

classical class NativeCompilerOptionsIdentity {
  state long profileLength = 0;
  state long sourceMaps = 0;
  state long published = 0;

  private long writeHeader(borrow mut bytes expected) {
    writeAscii(expected, 0, "schema: 1");
    setByte(expected, 9, 10);
    writeAscii(expected, 10, "compiler:");
    setByte(expected, 19, 10);
    setByte(expected, 20, 32);
    setByte(expected, 21, 32);
    writeAscii(expected, 22, "profile: ");
    setByte(expected, 31, 34);
    return 32;
  }

  private long writeSourceMapsPrefix(borrow mut bytes expected) {
    setByte(expected, 0, 34);
    setByte(expected, 1, 10);
    setByte(expected, 2, 32);
    setByte(expected, 3, 32);
    writeAscii(expected, 4, "source-maps: ");
    return 17;
  }

  /// Publishes SHA-256 only for exact canonical schema-1 options.
  ///
  /// - Effects: Mutates fixture state and caller-owned identity output.
  entry void main(borrow byteview source, borrow mut bytes identity) {
    requireMetadata(bufferLength(source) < 257, source);
    requireMetadata(31 < bufferLength(identity), source);
    region arena = new region(1300, 6);
    bytes expected = allocateBytes(arena, 64);
    long expectedLength = writeHeader(expected);
    long cursor = consumeMetadata(source, 0, expected, expectedLength);
    long profileStart = cursor;
    while (cursor < bufferLength(source)) limit 128 {
      if (source[cursor] == 34) {
        break;
      }

      requireMetadata(profileByte(source[cursor], cursor == profileStart), source);
      cursor += 1;
    }

    long parsedProfileLength = cursor - profileStart;
    requireMetadata(0 < parsedProfileLength, source);
    requireMetadata(parsedProfileLength < 129, source);
    expectedLength = writeSourceMapsPrefix(expected);
    cursor = consumeMetadata(source, cursor, expected, expectedLength);
    long parsedSourceMaps = 0;
    if (source[cursor] == 102) {
      writeAscii(expected, 0, "false");
      cursor = consumeMetadata(source, cursor, expected, 5);
    } else {
      writeAscii(expected, 0, "true");
      cursor = consumeMetadata(source, cursor, expected, 4);
      parsedSourceMaps = 1;
    }

    setByte(expected, 0, 10);
    cursor = consumeMetadata(source, cursor, expected, 1);
    requireMetadata(cursor == bufferLength(source), source);
    publishSha256(source, identity, arena);
    profileLength = parsedProfileLength;
    sourceMaps = parsedSourceMaps;
    published = 1;
    setOutputLength(identity, 32);
    drop(expected);
    drop(arena);
  }
}
