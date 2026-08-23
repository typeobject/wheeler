//! Checks physical resolved local-loop operand decoders through native package tests.

module wheeler.compiler.tests.native_compiler_resolved_local_loop_operands;

import wheeler.compiler.resolved_local_loop_operands;

classical class NativeCompilerResolvedLocalLoopOperandTests {
  entry void main() {
    assert(true);
  }

  test void checksResolvedLoopTarget() {
    long target = resolvedLocalWhileTarget(18779);
    assert(target == 3);
  }

  test void checksResolvedLoopForm() {
    long form = resolvedLocalWhileForm(18779);
    assert(form == 19);
  }
}
