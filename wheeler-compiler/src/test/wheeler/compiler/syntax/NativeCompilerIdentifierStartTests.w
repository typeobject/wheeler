//! Checks the physical identifier-start classifier through native package tests.

module wheeler.compiler.tests.native_compiler_identifier_starts;

import wheeler.compiler.identifier_starts;

classical class NativeCompilerIdentifierStartTests {
  entry void main() {
    assert(true);
  }

  test void checksFinalLowercaseIdentifierStart() {
    boolean present = identifierStart(122);
    assert(present);
  }
}
