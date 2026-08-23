//! Checks physical local-literal comparison source decoders through native package tests.

module wheeler.compiler.tests.native_compiler_resolved_local_literal_sources;

import wheeler.compiler.resolved_local_literal_comparison_sources;

classical class NativeCompilerResolvedLocalLiteralSourceTests {
  entry void main() {
    assert(true);
  }

  test void decodesEqualitySource() {
    long source = resolvedLocalLiteralComparisonSource(12031);
    assert(source == 255);
  }

  test void decodesLessThanSource() {
    long source = resolvedLocalLiteralComparisonSource(12287);
    assert(source == 255);
  }

  test void decodesInequalitySource() {
    long source = resolvedLocalLiteralComparisonSource(16127);
    assert(source == 255);
  }
}
