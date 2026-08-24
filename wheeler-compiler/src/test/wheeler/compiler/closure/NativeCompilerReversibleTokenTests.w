//! Checks physical reversible token advancement through native package tests.

module wheeler.compiler.tests.native_compiler_reversible_tokens;

import wheeler.compiler.closure.reversible_token_coordinates;
import wheeler.compiler.source_scalars;

classical class NativeCompilerReversibleTokenTests {
  entry void main() {
    assert(true);
  }

  test void advancesSourceTokensReversibly() {
    long advanced = nextSourceToken(SCALAR_DIGIT_ONE);
    assert(advanced == 50);
  }
}
