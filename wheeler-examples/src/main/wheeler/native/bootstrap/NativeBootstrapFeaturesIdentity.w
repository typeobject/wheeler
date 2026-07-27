//! Verifies and identifies the closed canonical bootstrap feature vocabulary.

module examples.bootstrap.features_identity;

import examples.bootstrap.syntax;
import wheeler.crypto.content_identity;

classical class NativeBootstrapFeaturesIdentity {
  state long featureCount = 0;
  state long manifestLength = 0;
  state long published = 0;

  private long writeHeader(borrow mut bytes expected) {
    writeAscii(expected, 0, "schema: 1");
    setByte(expected, 9, 10);
    writeAscii(expected, 10, "profile: ");
    setByte(expected, 19, 34);
    writeAscii(expected, 20, "bootstrap-1");
    setByte(expected, 31, 34);
    setByte(expected, 32, 10);
    writeAscii(expected, 33, "features:");
    setByte(expected, 42, 10);
    return 43;
  }

  private long writeFeaturePrefix(borrow mut bytes expected, long cursor) {
    writeAscii(expected, cursor, "  - name: ");
    cursor += 10;
    setByte(expected, cursor, 34);
    return cursor + 1;
  }

  private long writeFeatureSuffix(borrow mut bytes expected, long cursor) {
    setByte(expected, cursor, 34);
    setByte(expected, cursor + 1, 10);
    writeAscii(expected, cursor + 2, "    version: 1");
    setByte(expected, cursor + 16, 10);
    return cursor + 17;
  }

  /// Publishes SHA-256 only for the complete canonical `bootstrap-1` vocabulary.
  ///
  /// - Effects: Mutates fixture state and caller-owned identity output.
  entry void main(borrow byteview source, borrow mut bytes identity) {
    requireMetadata(bufferLength(source) < 2049, source);
    requireMetadata(31 < bufferLength(identity), source);
    region arena = new region(3300, 6);
    bytes expected = allocateBytes(arena, 2048);
    long cursor = writeHeader(expected);

    cursor = writeFeaturePrefix(expected, cursor);
    writeAscii(expected, cursor, "affine-borrows");
    cursor = writeFeatureSuffix(expected, cursor + 14);
    cursor = writeFeaturePrefix(expected, cursor);
    writeAscii(expected, cursor, "boolean-scalars");
    cursor = writeFeatureSuffix(expected, cursor + 15);
    cursor = writeFeaturePrefix(expected, cursor);
    writeAscii(expected, cursor, "bounded-loops");
    cursor = writeFeatureSuffix(expected, cursor + 13);
    cursor = writeFeaturePrefix(expected, cursor);
    writeAscii(expected, cursor, "byte-output");
    cursor = writeFeatureSuffix(expected, cursor + 11);
    cursor = writeFeaturePrefix(expected, cursor);
    writeAscii(expected, cursor, "byteview-input");
    cursor = writeFeatureSuffix(expected, cursor + 14);
    cursor = writeFeaturePrefix(expected, cursor);
    writeAscii(expected, cursor, "checked-arithmetic");
    cursor = writeFeatureSuffix(expected, cursor + 18);
    cursor = writeFeaturePrefix(expected, cursor);
    writeAscii(expected, cursor, "compile-time-constants");
    cursor = writeFeatureSuffix(expected, cursor + 22);
    cursor = writeFeaturePrefix(expected, cursor);
    writeAscii(expected, cursor, "exhaustive-variants");
    cursor = writeFeatureSuffix(expected, cursor + 19);
    cursor = writeFeaturePrefix(expected, cursor);
    writeAscii(expected, cursor, "fixed-scalar-array-fields");
    cursor = writeFeatureSuffix(expected, cursor + 25);
    cursor = writeFeaturePrefix(expected, cursor);
    writeAscii(expected, cursor, "generated-inverse-proofs");
    cursor = writeFeatureSuffix(expected, cursor + 24);
    cursor = writeFeaturePrefix(expected, cursor);
    writeAscii(expected, cursor, "module-linking");
    cursor = writeFeatureSuffix(expected, cursor + 14);
    cursor = writeFeaturePrefix(expected, cursor);
    writeAscii(expected, cursor, "nominal-records");
    cursor = writeFeatureSuffix(expected, cursor + 15);
    cursor = writeFeaturePrefix(expected, cursor);
    writeAscii(expected, cursor, "owned-regions");
    cursor = writeFeatureSuffix(expected, cursor + 13);
    cursor = writeFeaturePrefix(expected, cursor);
    writeAscii(expected, cursor, "signed-scalars");
    cursor = writeFeatureSuffix(expected, cursor + 14);
    cursor = writeFeaturePrefix(expected, cursor);
    writeAscii(expected, cursor, "static-calls");
    cursor = writeFeatureSuffix(expected, cursor + 12);
    cursor = writeFeaturePrefix(expected, cursor);
    writeAscii(expected, cursor, "strict-utf8-input");
    cursor = writeFeatureSuffix(expected, cursor + 17);
    cursor = writeFeaturePrefix(expected, cursor);
    writeAscii(expected, cursor, "word-buffers");
    cursor = writeFeatureSuffix(expected, cursor + 12);

    long consumed = consumeMetadata(source, 0, expected, cursor);
    requireMetadata(consumed == bufferLength(source), source);
    publishSha256(source, identity, arena);
    featureCount = 17;
    manifestLength = cursor;
    published = 1;
    setOutputLength(identity, 32);
    drop(expected);
    drop(arena);
  }
}
