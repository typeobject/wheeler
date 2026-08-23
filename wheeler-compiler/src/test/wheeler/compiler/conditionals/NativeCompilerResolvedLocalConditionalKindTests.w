//! Checks physical resolved local-conditional classifiers through native package tests.

module wheeler.compiler.tests.native_compiler_resolved_local_conditional_kinds;

import wheeler.compiler.resolved_local_conditional_kinds;

classical class NativeCompilerResolvedLocalConditionalKindTests {
  entry void main() {
    assert(true);
  }

  test void classifiesFinalResolvedLocalConditional() {
    boolean present = resolvedLocalConditional(11775);
    assert(present);
  }

  test void classifiesFinalNegatedResolvedLocalConditional() {
    boolean negated = resolvedLocalConditionalNegated(11775);
    assert(negated);
  }

  test void classifiesFinalResolvedLocalAssignment() {
    boolean assignment = resolvedLocalConditionalAssignment(10239);
    assert(assignment);
  }

  test void classifiesFinalResolvedLocalAssignmentValue() {
    boolean value = resolvedLocalConditionalAssignmentValue(10239);
    assert(value);
  }
}
