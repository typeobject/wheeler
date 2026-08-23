//! Checks physical resolved forwarding return calls through native package tests.

module wheeler.compiler.tests.native_compiler_resolved_return_calls;

import wheeler.compiler.resolved_return_call_kinds;

classical class NativeCompilerResolvedReturnCallTests {
  entry void main() {
    assert(true);
  }

  test void classifiesSevenArgumentReturnCall() {
    boolean present = resolvedReturnHelperCall(29952);
    assert(present);
  }

  test void decodesSevenArgumentReturnCallArity() {
    long arity = returnHelperCallArity(29952);
    assert(arity == 7);
  }

  test void decodesFinalFourArgumentFirstSource() {
    long source = returnHelperCallFirstSource(4328521727);
    assert(source == 255);
  }

  test void decodesFinalFourArgumentSecondSource() {
    long source = returnHelperCallSecondSource(4328521727);
    assert(source == 255);
  }

  test void decodesFinalFourArgumentThirdSource() {
    long source = returnHelperCallThirdSource(4328521727);
    assert(source == 255);
  }

  test void decodesFinalFourArgumentFourthSource() {
    long source = returnHelperCallFourthSource(4328521727);
    assert(source == 255);
  }
}
