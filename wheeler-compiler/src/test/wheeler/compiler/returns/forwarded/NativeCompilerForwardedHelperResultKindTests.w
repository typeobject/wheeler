//! Checks resolved forwarding-result membership through native package tests.

module wheeler.compiler.tests.native_compiler_forwarded_helper_result_kinds;

import wheeler.compiler.forwarded_helper_result_kinds;

classical class NativeCompilerForwardedHelperResultKindTests {
  entry void main() {
    assert(true);
  }

  test void classifiesSevenArgumentReturnCall() {
    boolean present = resolvedReturnHelperCall(29952);
    assert(present);
  }

  test void rejectsOpcodeAfterFourArgumentColumn() {
    boolean present = resolvedReturnHelperCall(4328521728);
    boolean rejected = !present;
    assert(rejected);
  }
}
