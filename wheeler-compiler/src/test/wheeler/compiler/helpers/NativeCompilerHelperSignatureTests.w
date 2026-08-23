//! Checks the physical helper parameter-count map through native package tests.

module wheeler.compiler.tests.native_compiler_helper_signatures;

import wheeler.compiler.helper_signatures;

classical class NativeCompilerHelperSignatureTests {
  entry void main() {
    assert(true);
  }

  test void checksSixteenParameterHelper() {
    long count = parameterCountForHelper(48);
    assert(count == 16);
  }
}
