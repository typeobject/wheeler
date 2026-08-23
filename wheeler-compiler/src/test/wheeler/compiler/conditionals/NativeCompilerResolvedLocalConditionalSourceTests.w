//! Checks physical resolved local-conditional source classifiers through native package tests.

module wheeler.compiler.tests.native_compiler_resolved_local_conditional_sources;

import wheeler.compiler.resolved_local_conditional_sources;

classical class NativeCompilerResolvedLocalConditionalSourceTests {
  entry void main() {
    assert(true);
  }

  test void classifiesFinalResolvedLocalConditionalValue() {
    boolean value = resolvedLocalConditionalValue(11775);
    assert(value);
  }

  test void classifiesFinalResolvedLocalConditionalSubtract() {
    boolean subtract = resolvedLocalConditionalSubtract(11519);
    assert(subtract);
  }

  test void classifiesFinalResolvedLocalConditionalXor() {
    boolean xor = resolvedLocalConditionalXor(11775);
    assert(xor);
  }
}
