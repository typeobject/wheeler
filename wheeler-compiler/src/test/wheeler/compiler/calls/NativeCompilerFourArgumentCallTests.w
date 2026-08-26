//! Checks physical four-argument call classification and decoding through native package tests.

module wheeler.compiler.tests.native_compiler_four_argument_calls;

import wheeler.compiler.four_argument_calls;

classical class NativeCompilerFourArgumentCallTests {
  entry void main() {
    assert(true);
  }

  test void classifiesFinalFourArgumentCall() {
    boolean call = fourArgumentCallStatement(327679);
    assert(call);
  }

  test void classifiesFirstBooleanFourArgumentCall() tags(call.boolean, call.four) {
    boolean call = fourArgumentCallStatement(327680);
    boolean booleanCall = fourArgumentBooleanCall(327680);
    assert(call);
    assert(booleanCall);
  }

  test void mapsFinalFourArgumentToken() {
    long token = fourArgumentCallFourthToken(244);
    assert(token == 255);
  }

  test void decodesFinalFourArgumentThirdSource() {
    long source = fourArgumentCallThirdSource(327679);
    assert(source == 255);
  }

  test void decodesFinalFourArgumentFourthSource() {
    long source = fourArgumentCallFourthSource(327679);
    assert(source == 255);
  }

  test void decodesFinalBooleanFourArgumentThirdSource() tags(call.boolean, call.four) {
    long source = fourArgumentCallThirdSource(393215);
    assert(source == 255);
  }

  test void decodesFinalBooleanFourArgumentFourthSource() tags(call.boolean, call.four) {
    long source = fourArgumentCallFourthSource(393215);
    assert(source == 255);
  }
}
