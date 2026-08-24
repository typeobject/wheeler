//! Checks physical unresolved local-assignment classification through native package tests.

module wheeler.compiler.tests.native_compiler_named_local_assignment_kinds;

import wheeler.compiler.named_local_assignment_kinds;

classical class NativeCompilerNamedLocalAssignmentKindTests {
  entry void main() {
    assert(true);
  }

  test void classifiesFinalNamedLocalAssignment() {
    boolean assignment = localAssignmentSourceStatement(805);
    assert(assignment);
  }
}
