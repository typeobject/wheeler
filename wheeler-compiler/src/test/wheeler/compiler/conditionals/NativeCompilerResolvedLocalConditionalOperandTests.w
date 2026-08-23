//! Checks physical resolved local-conditional operand decoding through native package tests.

module wheeler.compiler.tests.native_compiler_resolved_local_conditional_operands;

import wheeler.compiler.resolved_local_conditional_operands;

classical class NativeCompilerResolvedLocalConditionalOperandTests {
  entry void main() {
    assert(true);
  }

  test void decodesFinalConditionalSource() {
    long source = resolvedLocalConditionalSource(11775);
    assert(source == 255);
  }
}
