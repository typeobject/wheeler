//! Checks both physical assignment-call identity maps through native package tests.

module wheeler.compiler.tests.native_compiler_call_columns;

import wheeler.compiler.assignment_call_columns;

classical class NativeCompilerCallColumnTests {
  entry void main() {
    assert(true);
  }

  test void checksSevenArgumentSourceKind() {
    long kind = sourceKind(7);
    assert(kind == 933);
  }

  test void checksSevenArgumentResolvedBase() {
    long base = resolvedBase(7);
    assert(base == 41792);
  }
}
