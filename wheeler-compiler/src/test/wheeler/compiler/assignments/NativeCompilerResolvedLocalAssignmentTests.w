//! Checks physical resolved local-assignment queries through native package tests.

module wheeler.compiler.tests.native_compiler_resolved_local_assignments;

import wheeler.compiler.resolved_local_assignments;

classical class NativeCompilerResolvedLocalAssignmentTests {
  entry void main() {
    assert(true);
  }

  test void checksResolvedAssignmentMembership() {
    boolean present = resolvedLocalAssignment(18687);
    assert(present);
  }

  test void checksResolvedNamedAssignmentMembership() {
    boolean present = resolvedLocalAssignmentNamed(17920);
    assert(present);
  }

  test void checksResolvedBooleanAssignmentMembership() {
    boolean present = resolvedLocalAssignmentBoolean(18176);
    assert(present);
  }

  test void checksResolvedAssignmentTarget() {
    long target = resolvedLocalAssignmentTarget(18432);
    assert(target == 0);
  }
}
