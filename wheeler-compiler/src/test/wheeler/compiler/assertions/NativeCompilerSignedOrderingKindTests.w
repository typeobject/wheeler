//! Checks complete signed ordering operand origins through native package tests.

module wheeler.compiler.tests.native_compiler_signed_ordering_kinds;

import wheeler.compiler.signed_ordering_kinds;

classical class NativeCompilerSignedOrderingKindTests {
  entry void main() {
    assert(true);
  }

  test void classifiesTheLastOriginPairAndRejectsTheNext() {
    long globalKind = 2;
    long next = 43017;
    long last = signedOrderingKind(globalKind, globalKind);
    boolean present = signedOrderingStatement(last);
    boolean excess = signedOrderingStatement(next);
    boolean absent = !excess;
    assert(last == 43016);
    assert(present);
    assert(absent);
  }

  test void retainsBothOrderedOperandOrigins() {
    long localKind = 1;
    long globalKind = 2;
    long code = signedOrderingKind(localKind, globalKind);
    long left = signedOrderingLeftKind(code);
    long right = signedOrderingRightKind(code);
    assert(left == 1);
    assert(right == 2);
  }

  test void keepsTheLocalAndStateIndexLimitsSeparateFromLiteralValues() {
    long literalKind = 0;
    long localKind = 1;
    long globalKind = 2;
    long minimum = -9223372036854775808;
    long lastLocal = 255;
    long nextLocal = 256;
    long firstState = 0;
    long secondState = 1;
    boolean literal = signedOrderingValueValid(literalKind, minimum);
    boolean local = signedOrderingValueValid(localKind, lastLocal);
    boolean excess = signedOrderingValueValid(localKind, nextLocal);
    boolean state = signedOrderingValueValid(globalKind, firstState);
    boolean second = signedOrderingValueValid(globalKind, secondState);
    boolean excessRejected = !excess;
    boolean secondRejected = !second;
    assert(literal);
    assert(local);
    assert(excessRejected);
    assert(state);
    assert(secondRejected);
  }
}
