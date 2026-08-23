//! Checks all physical assignment-call identity queries through native package tests.

module wheeler.compiler.tests.native_compiler_call_kinds;

import wheeler.compiler.assignment_call_kinds;

classical class NativeCompilerCallKindTests {
  entry void main() {
    assert(true);
  }

  test void checksSevenArgumentSourceMembership() {
    boolean present = assignmentCallSourceStatement(933);
    assert(present);
  }

  test void checksSevenArgumentResolvedMembership() {
    boolean present = assignmentCallStatement(41834);
    assert(present);
  }

  test void checksSevenArgumentResolvedIdentity() {
    long opcode = resolvedAssignmentCall(7, 42);
    assert(opcode == 41834);
  }

  test void checksSevenArgumentResolvedTarget() {
    long target = assignmentCallTarget(41834);
    assert(target == 42);
  }
}
