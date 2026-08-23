//! Checks physical resolved local-loop form decoders through native package tests.

module wheeler.compiler.tests.native_compiler_resolved_local_loop_forms;

import wheeler.compiler.resolved_local_loop_forms;

classical class NativeCompilerResolvedLocalLoopFormTests {
  entry void main() {
    assert(true);
  }

  test void checksNamedConditionBit() {
    long condition = localWhileConditionBit(1);
    assert(condition == 1);
  }

  test void checksNamedLimitPair() {
    long limit = localWhileLimitPair(2);
    assert(limit == 1);
  }

  test void checksReversedCondition() {
    boolean reversed = localWhileReversed(16);
    assert(reversed);
  }

  test void checksReversedUpdateBits() {
    long update = localWhileUpdateBits(19);
    assert(update == 3);
  }
}
