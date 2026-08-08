//! Verifies canonical bootstrap toolchain provenance before identifying it.

module wheeler.conformance.bootstrap.toolchain_identity;

import wheeler.compiler.closure.manifest_syntax;
import wheeler.crypto.content_identity;

classical class NativeToolchainIdentity {
  state long kindCode = 0;
  state long identityCount = 0;
  state long published = 0;

  /// Publishes SHA-256 only for one complete canonical schema-1 toolchain record.
  ///
  /// - Effects: Mutates fixture state and caller-owned identity output.
  entry void main(borrow byteview source, borrow mut bytes identity) {
    requireMetadata(bufferLength(source) < 513, source);
    requireMetadata(31 < bufferLength(identity), source);
    region arena = new region(1800, 6);
    bytes expected = allocateBytes(arena, 512);
    writeAscii(expected, 0, "schema: 1");
    setByte(expected, 9, 10);
    writeAscii(expected, 10, "toolchain:");
    setByte(expected, 20, 10);
    writeAscii(expected, 21, "  kind: ");
    setByte(expected, 29, 34);
    long cursor = consumeMetadata(source, 0, expected, 30);

    long acceptedKind = 0;
    long first = source[cursor];
    if (first == 114) {
      writeAscii(expected, 0, "recovery-seed");
      cursor = consumeMetadata(source, cursor, expected, 13);
      acceptedKind = 1;
    }

    if (first == 105) {
      writeAscii(expected, 0, "independent-stage0");
      cursor = consumeMetadata(source, cursor, expected, 18);
      acceptedKind = 2;
    }

    if (first == 104) {
      writeAscii(expected, 0, "host-source");
      cursor = consumeMetadata(source, cursor, expected, 11);
      acceptedKind = 3;
    }

    requireMetadata(0 < acceptedKind, source);

    setByte(expected, 0, 34);
    setByte(expected, 1, 10);
    writeAscii(expected, 2, "  source: ");
    cursor = consumeMetadata(source, cursor, expected, 12);
    cursor = consumeQuotedIdentity(source, cursor, expected);
    setByte(expected, 0, 10);
    writeAscii(expected, 1, "  builder: ");
    cursor = consumeMetadata(source, cursor, expected, 12);
    cursor = consumeQuotedIdentity(source, cursor, expected);
    setByte(expected, 0, 10);
    writeAscii(expected, 1, "  dependencies: ");
    cursor = consumeMetadata(source, cursor, expected, 17);
    cursor = consumeQuotedIdentity(source, cursor, expected);
    setByte(expected, 0, 10);
    writeAscii(expected, 1, "  environment: ");
    cursor = consumeMetadata(source, cursor, expected, 16);
    cursor = consumeQuotedIdentity(source, cursor, expected);
    setByte(expected, 0, 10);
    cursor = consumeMetadata(source, cursor, expected, 1);
    requireMetadata(cursor == bufferLength(source), source);

    publishSha256(source, identity, arena);
    kindCode = acceptedKind;
    identityCount = 4;
    published = 1;
    setOutputLength(identity, 32);
    drop(expected);
    drop(arena);
  }
}
