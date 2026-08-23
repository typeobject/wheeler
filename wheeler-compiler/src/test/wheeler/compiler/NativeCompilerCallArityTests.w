//! Checks a physical compiler call-assignment arity decoder through native package tests.

module wheeler.compiler.tests.native_compiler_call_arity;

import wheeler.compiler.assignment_call_arities;
import wheeler.compiler.assignment_call_identities;

classical class NativeCompilerCallArityTests {
  entry void main() {
    assert(true);
  }

  test void checksSevenArgumentAssignmentCall() {
    long arity = assignmentCallArity(933);
    assert(arity == 7);
    long source = STATEMENT_ASSIGN_CALL_SEVEN_NAMED;
    assert(source == 933);
  }
}
