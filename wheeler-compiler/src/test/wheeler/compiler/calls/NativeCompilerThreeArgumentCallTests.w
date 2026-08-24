//! Checks physical three-argument call classification and decoding through native package tests.

module wheeler.compiler.tests.native_compiler_three_argument_calls;

import wheeler.compiler.three_argument_calls;

classical class NativeCompilerThreeArgumentCallTests {
  entry void main() {
    assert(true);
  }

  test void classifiesFinalThreeArgumentCall() {
    boolean call = threeArgumentCallStatement(33023);
    assert(call);
  }

  test void mapsFinalThreeArgumentFirstToken() {
    long token = threeArgumentFirstToken(246);
    assert(token == 251);
  }

  test void mapsFinalThreeArgumentSecondToken() {
    long token = threeArgumentSecondToken(246);
    assert(token == 253);
  }

  test void mapsFinalThreeArgumentThirdToken() {
    long token = threeArgumentThirdToken(246);
    assert(token == 255);
  }

  test void decodesFinalThreeArgumentSource() {
    long source = threeArgumentThirdSource(33023);
    assert(source == 255);
  }
}
