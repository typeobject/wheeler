//! Checks the complete physical helper-value classifier through native package tests.

module wheeler.compiler.tests.native_compiler_helper_value_kinds;

import wheeler.compiler.helper_value_kinds;

classical class NativeCompilerHelperValueKindTests {
  entry void main() {
    assert(true);
  }

  test void classifiesOwnedAllocation() {
    boolean present = helperValueStatement(915);
    assert(present);
  }

  test void classifiesSevenArgumentVoidCall() {
    boolean present = helperValueStatement(925);
    assert(present);
  }

  test void classifiesBorrowedMapMutation() {
    boolean present = helperValueStatement(904);
    assert(present);
  }

  test void classifiesSevenLocalCall() {
    boolean present = helperValueStatement(921);
    assert(present);
  }

  test void classifiesTerminalLocalCallRange() {
    boolean present = helperValueStatement(857);
    assert(present);
  }

  test void classifiesTerminalLocalReturnRange() {
    boolean present = helperValueStatement(861);
    assert(present);
  }

  test void classifiesTerminalBooleanReturnRange() {
    boolean present = helperValueStatement(877);
    assert(present);
  }

  test void classifiesHelperCallReturn() {
    boolean present = helperValueStatement(890);
    assert(present);
  }

  test void classifiesFinalBorrowedReturn() {
    boolean present = helperValueStatement(911);
    assert(present);
  }

  test void classifiesFinalBorrowedLocal() {
    boolean present = helperValueStatement(896);
    assert(present);
  }
}
