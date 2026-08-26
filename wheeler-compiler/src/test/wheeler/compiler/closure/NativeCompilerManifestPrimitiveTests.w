//! Checks physical bootstrap manifest primitives through native package tests.

module wheeler.compiler.tests.native_compiler_manifest_primitives;

import wheeler.compiler.closure.manifest_assertions;
import wheeler.compiler.closure.manifest_profile;

classical class NativeCompilerManifestPrimitiveTests {
  entry void main() {
    assert(true);
  }

  test void acceptsMetadataCondition() tags(manifest.assertion, manifest.primitive) {
    boolean accepted = true;
    requireMetadata(accepted);
    assert(accepted);
  }

  test void acceptsAsciiDigitStart() tags(manifest.primitive, manifest.range) {
    long value = 48;
    boolean packagePunctuation = false;
    boolean fallback = false;
    boolean accepted = profileByte(value, packagePunctuation, fallback);
    assert(accepted);
  }

  test void acceptsAsciiDigitEnd() tags(manifest.primitive, manifest.range) {
    long value = 57;
    boolean packagePunctuation = false;
    boolean fallback = false;
    boolean accepted = profileByte(value, packagePunctuation, fallback);
    assert(accepted);
  }

  test void acceptsAsciiUpperStart() tags(manifest.primitive, manifest.range) {
    long value = 65;
    boolean packagePunctuation = false;
    boolean fallback = false;
    boolean accepted = profileByte(value, packagePunctuation, fallback);
    assert(accepted);
  }

  test void acceptsAsciiUpperEnd() tags(manifest.primitive, manifest.range) {
    long value = 90;
    boolean packagePunctuation = false;
    boolean fallback = false;
    boolean accepted = profileByte(value, packagePunctuation, fallback);
    assert(accepted);
  }

  test void acceptsAsciiLowerStart() tags(manifest.primitive, manifest.range) {
    long value = 97;
    boolean packagePunctuation = false;
    boolean fallback = false;
    boolean accepted = profileByte(value, packagePunctuation, fallback);
    assert(accepted);
  }

  test void acceptsAsciiLowerEnd() tags(manifest.primitive, manifest.range) {
    long value = 122;
    boolean packagePunctuation = false;
    boolean fallback = false;
    boolean accepted = profileByte(value, packagePunctuation, fallback);
    assert(accepted);
  }

  test void acceptsPackageDash() tags(manifest.primitive, manifest.punctuation) {
    long value = 45;
    boolean packagePunctuation = true;
    boolean fallback = false;
    boolean accepted = profileByte(value, packagePunctuation, fallback);
    assert(accepted);
  }

  test void acceptsPackageDot() tags(manifest.primitive, manifest.punctuation) {
    long value = 46;
    boolean packagePunctuation = true;
    boolean fallback = false;
    boolean accepted = profileByte(value, packagePunctuation, fallback);
    assert(accepted);
  }

  test void acceptsPackageUnderscore() tags(manifest.primitive, manifest.punctuation) {
    long value = 95;
    boolean packagePunctuation = true;
    boolean fallback = false;
    boolean accepted = profileByte(value, packagePunctuation, fallback);
    assert(accepted);
  }

  test void rejectsPlainDash() tags(manifest.primitive, manifest.punctuation) {
    long value = 45;
    boolean packagePunctuation = false;
    boolean fallback = false;
    boolean accepted = profileByte(value, packagePunctuation, fallback);
    boolean rejected = !accepted;
    assert(rejected);
  }

  test void rejectsPlainDot() tags(manifest.primitive, manifest.punctuation) {
    long value = 46;
    boolean packagePunctuation = false;
    boolean fallback = false;
    boolean accepted = profileByte(value, packagePunctuation, fallback);
    boolean rejected = !accepted;
    assert(rejected);
  }

  test void rejectsPlainUnderscore() tags(manifest.primitive, manifest.punctuation) {
    long value = 95;
    boolean packagePunctuation = false;
    boolean fallback = false;
    boolean accepted = profileByte(value, packagePunctuation, fallback);
    boolean rejected = !accepted;
    assert(rejected);
  }

  test void rejectsLowerGapDespiteFallback() tags(manifest.fallback, manifest.primitive) {
    long value = 47;
    boolean packagePunctuation = true;
    boolean fallback = true;
    boolean accepted = profileByte(value, packagePunctuation, fallback);
    boolean rejected = !accepted;
    assert(rejected);
  }

  test void acceptsHighFallback() tags(manifest.fallback, manifest.primitive) {
    long value = 123;
    boolean packagePunctuation = false;
    boolean fallback = true;
    boolean accepted = profileByte(value, packagePunctuation, fallback);
    assert(accepted);
  }

  test void rejectsDisabledHighFallback() tags(manifest.fallback, manifest.primitive) {
    long value = 123;
    boolean packagePunctuation = true;
    boolean fallback = false;
    boolean accepted = profileByte(value, packagePunctuation, fallback);
    boolean rejected = !accepted;
    assert(rejected);
  }
}
