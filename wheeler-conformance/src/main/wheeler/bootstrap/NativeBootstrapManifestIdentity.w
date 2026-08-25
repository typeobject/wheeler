//! Validates complete fixed-point and diverse-bootstrap evidence before identifying it.

module wheeler.conformance.bootstrap.manifest_identity;

import wheeler.compiler.closure.manifest_profile;
import wheeler.compiler.closure.manifest_syntax;
import wheeler.crypto.content_identity;

classical class NativeBootstrapManifestIdentity {
  state long identityCount = 0;
  state long semanticChecks = 0;
  state long published = 0;

  private long consumeIdentity(
    borrow byteview source,
    long cursor,
    borrow mut bytes expected,
    long prefixLength
  ) {
    cursor = consumeMetadata(source, cursor, expected, prefixLength);
    return consumeQuotedIdentity(source, cursor);
  }

  private void requireSameIdentity(borrow byteview source, long left, long right) {
    boolean same = true;
    long index = 0;
    while (index < 64) limit 64 {
      if ((source[left + index + 1] == source[right + index + 1]) == false) {
        same = false;
      }

      index += 1;
    }

    requireMetadata(same, source);
  }

  private void requireDifferentIdentity(borrow byteview source, long left, long right) {
    boolean different = false;
    long index = 0;
    while (index < 64) limit 64 {
      if ((source[left + index + 1] == source[right + index + 1]) == false) {
        different = true;
      }

      index += 1;
    }

    requireMetadata(different, source);
  }

  /// Publishes SHA-256 only for canonical schema-2 recovery evidence.
  ///
  /// - Effects: Mutates fixture state and caller-owned identity output.
  entry void main(borrow byteview source, borrow mut bytes identity) {
    requireMetadata(bufferLength(source) < 2049, source);
    requireMetadata(31 < bufferLength(identity), source);
    region arena = new region(1500, 6);
    bytes expected = allocateBytes(arena, 256);
    writeAscii(expected, 0, "schema: 2");
    setByte(expected, 9, 10);
    writeAscii(expected, 10, "source:");
    setByte(expected, 17, 10);
    writeAscii(expected, 18, "  archive: ");
    long cursor = consumeIdentity(source, 0, expected, 29);

    setByte(expected, 0, 10);
    writeAscii(expected, 1, "  manifest: ");
    cursor = consumeIdentity(source, cursor, expected, 13);
    setByte(expected, 0, 10);
    writeAscii(expected, 1, "  lock: ");
    cursor = consumeIdentity(source, cursor, expected, 9);
    setByte(expected, 0, 10);
    writeAscii(expected, 1, "  profile: ");
    setByte(expected, 12, 34);
    cursor = consumeMetadata(source, cursor, expected, 13);
    long profileStart = cursor;
    while (cursor < bufferLength(source)) limit 128 {
      if (source[cursor] == 34) {
        break;
      }

      requireMetadata(
        profileByte(source[cursor], cursor != profileStart, /* valid= */ false),
        source
      );
      cursor += 1;
    }

    requireMetadata(profileStart < cursor, source);
    requireMetadata(cursor - profileStart < 129, source);

    setByte(expected, 0, 34);
    setByte(expected, 1, 10);
    writeAscii(expected, 2, "  features: ");
    cursor = consumeIdentity(source, cursor, expected, 14);
    setByte(expected, 0, 10);
    writeAscii(expected, 1, "  modules: ");
    cursor = consumeIdentity(source, cursor, expected, 12);
    setByte(expected, 0, 10);
    writeAscii(expected, 1, "  options: ");
    cursor = consumeIdentity(source, cursor, expected, 12);
    setByte(expected, 0, 10);
    writeAscii(expected, 1, "  limits: ");
    cursor = consumeIdentity(source, cursor, expected, 11);

    setByte(expected, 0, 10);
    writeAscii(expected, 1, "ordinary:");
    setByte(expected, 10, 10);
    writeAscii(expected, 11, "  toolchain: ");
    long ordinaryToolchain = cursor + 24;
    cursor = consumeIdentity(source, cursor, expected, 24);
    setByte(expected, 0, 10);
    writeAscii(expected, 1, "  compiler: ");
    long ordinaryCompiler = cursor + 13;
    cursor = consumeIdentity(source, cursor, expected, 13);
    setByte(expected, 0, 10);
    writeAscii(expected, 1, "  runtime: ");
    cursor = consumeIdentity(source, cursor, expected, 12);
    setByte(expected, 0, 10);
    writeAscii(expected, 1, "  verifier: ");
    cursor = consumeIdentity(source, cursor, expected, 13);
    setByte(expected, 0, 10);
    writeAscii(expected, 1, "  stage-1: ");
    long stageOne = cursor + 12;
    cursor = consumeIdentity(source, cursor, expected, 12);
    setByte(expected, 0, 10);
    writeAscii(expected, 1, "  stage-2: ");
    long stageTwo = cursor + 12;
    cursor = consumeIdentity(source, cursor, expected, 12);
    requireSameIdentity(source, stageOne, stageTwo);
    setByte(expected, 0, 10);
    writeAscii(expected, 1, "  diagnostics: ");
    long ordinaryDiagnostics = cursor + 16;
    cursor = consumeIdentity(source, cursor, expected, 16);

    setByte(expected, 0, 10);
    writeAscii(expected, 1, "diverse:");
    setByte(expected, 9, 10);
    writeAscii(expected, 10, "  toolchain: ");
    long diverseToolchain = cursor + 23;
    cursor = consumeIdentity(source, cursor, expected, 23);
    requireDifferentIdentity(source, ordinaryToolchain, diverseToolchain);
    setByte(expected, 0, 10);
    writeAscii(expected, 1, "  compiler: ");
    long diverseCompiler = cursor + 13;
    cursor = consumeIdentity(source, cursor, expected, 13);
    requireDifferentIdentity(source, ordinaryCompiler, diverseCompiler);
    setByte(expected, 0, 10);
    writeAscii(expected, 1, "  runtime: ");
    cursor = consumeIdentity(source, cursor, expected, 12);
    setByte(expected, 0, 10);
    writeAscii(expected, 1, "  verifier: ");
    cursor = consumeIdentity(source, cursor, expected, 13);
    setByte(expected, 0, 10);
    writeAscii(expected, 1, "  output: ");
    long diverseOutput = cursor + 11;
    cursor = consumeIdentity(source, cursor, expected, 11);
    requireSameIdentity(source, stageOne, diverseOutput);
    setByte(expected, 0, 10);
    writeAscii(expected, 1, "  diagnostics: ");
    long diverseDiagnostics = cursor + 16;
    cursor = consumeIdentity(source, cursor, expected, 16);
    requireSameIdentity(source, ordinaryDiagnostics, diverseDiagnostics);

    setByte(expected, 0, 10);
    writeAscii(expected, 1, "acceptance:");
    setByte(expected, 12, 10);
    writeAscii(expected, 13, "  artifact-set: ");
    cursor = consumeIdentity(source, cursor, expected, 29);
    setByte(expected, 0, 10);
    cursor = consumeMetadata(source, cursor, expected, 1);
    requireMetadata(cursor == bufferLength(source), source);

    publishSha256(source, identity, arena);
    identityCount = 21;
    semanticChecks = 5;
    published = 1;
    setOutputLength(identity, 32);
    drop(expected);
    drop(arena);
  }
}
