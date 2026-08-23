//! Checks physical unresolved local-conditional classifiers through native package tests.

module wheeler.compiler.tests.native_compiler_named_local_conditional_kinds;

import wheeler.compiler.named_local_conditional_kinds;

classical class NativeCompilerNamedLocalConditionalKindTests {
  entry void main() {
    assert(true);
  }

  test void classifiesFinalNamedLocalConditional() {
    boolean present = namedLocalConditional(814);
    assert(present);
  }

  test void classifiesFinalNegatedNamedLocalConditional() {
    boolean negated = namedLocalConditionalNegated(814);
    assert(negated);
  }

  test void classifiesFinalNamedLocalAssignment() {
    boolean assignment = namedLocalConditionalAssignment(804);
    assert(assignment);
  }

  test void classifiesFinalNamedLocalAssignmentValue() {
    boolean value = namedLocalConditionalAssignmentValue(804);
    assert(value);
  }
}
