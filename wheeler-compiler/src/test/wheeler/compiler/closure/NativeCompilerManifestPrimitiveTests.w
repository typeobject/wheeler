//! Checks physical bootstrap manifest primitives through native package tests.

module wheeler.compiler.tests.native_compiler_manifest_primitives;

import wheeler.compiler.closure.manifest_assertions;
import wheeler.compiler.closure.manifest_profile;

classical class NativeCompilerManifestPrimitiveTests {
  entry void main() {
    assert(true);
  }

  test void acceptsMetadataCondition() tags(manifest.primitive) {
    requireMetadata(true);
    assert(true);
  }

  test void classifiesAsciiDigitsAndLetters() tags(manifest.primitive) {
    assert(profileByte(48, false, false));
    assert(profileByte(57, false, false));
    assert(profileByte(65, false, false));
    assert(profileByte(90, false, false));
    assert(profileByte(97, false, false));
    assert(profileByte(122, false, false));
  }

  test void gatesProfilePunctuation() tags(manifest.primitive) {
    assert(profileByte(45, true, false));
    assert(profileByte(46, true, false));
    assert(profileByte(95, true, false));
    assert(profileByte(45, false, false) == false);
    assert(profileByte(46, false, false) == false);
    assert(profileByte(95, false, false) == false);
  }

  test void preservesOutOfRangeFallback() tags(manifest.primitive) {
    assert(profileByte(47, true, true) == false);
    assert(profileByte(123, false, true));
    assert(profileByte(123, true, false) == false);
  }
}
