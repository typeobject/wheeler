package com.typeobject.wheeler.examples;

import java.util.List;
import org.junit.jupiter.api.Test;

/** Lexical presence, scalar type, and value admission are separate assertion contracts. */
final class NativeCompilerSignedAssertionBindingExampleTest {
  private static final List<String> OWNERS = List.of(
      "wheeler.compiler.compiler_token_limits", "wheeler.compiler.signed_assertion_values");

  @Test
  void countsWrongTypeAndAmbiguousLocalsBeforeConstantsOrStateAndRewinds() throws Exception {
    var program = NativeSourceFrontFixture.program(OWNERS, 4096, "", """
        assert(count == 53);
        region scratch = new region(/* bytes= */ 32, /* allocations= */ 1);
        words prior = allocate(scratch, 4);
        SignedAssertionValue constant = resolveSignedAssertionValue(source, starts, lengths, prior, 0, 46);
        assert(constant.valid);
        assert(constant.kind == 0);
        assert(constant.value == -7);
        SignedAssertionValue wrongConstant = resolveSignedAssertionValue(source, starts, lengths, prior, 0, 13);
        assert(!wrongConstant.valid);
        set(prior, 0, 29);
        SignedAssertionValue local = resolveSignedAssertionValue(source, starts, lengths, prior, 1, 46);
        assert(local.valid);
        assert(local.kind == 1);
        assert(local.value == 1);
        set(prior, 0, 34);
        SignedAssertionValue wrongLocal = resolveSignedAssertionValue(source, starts, lengths, prior, 1, 46);
        assert(!wrongLocal.valid);
        set(prior, 0, 29);
        set(prior, 1, 34);
        SignedAssertionValue ambiguous = resolveSignedAssertionValue(source, starts, lengths, prior, 2, 46);
        assert(!ambiguous.valid);
        set(prior, 0, -30);
        SignedAssertionValue parameter = resolveSignedAssertionValue(source, starts, lengths, prior, 1, 46);
        assert(parameter.valid);
        assert(parameter.kind == 1);
        assert(parameter.value == 0);
        set(prior, 0, -30 - BOOLEAN_PARAMETER_TOKEN_BIAS);
        SignedAssertionValue wrongParameter = resolveSignedAssertionValue(source, starts, lengths, prior, 1, 46);
        assert(!wrongParameter.valid);
        set(prior, 0, 39);
        SignedAssertionValue absentLocal = resolveSignedAssertionValue(source, starts, lengths, prior, 1, 46);
        assert(absentLocal.valid);
        assert(absentLocal.kind == 0);
        assert(absentLocal.value == -7);
        set(starts, COMPILER_GLOBAL_NAME_TOKEN, starts[19]);
        set(lengths, COMPILER_GLOBAL_NAME_TOKEN, lengths[19]);
        SignedAssertionValue state = resolveSignedAssertionValue(source, starts, lengths, prior, 0, 48);
        assert(state.valid);
        assert(state.kind == 2);
        assert(state.value == 0);
        set(prior, 0, -19 - BOOLEAN_PARAMETER_TOKEN_BIAS);
        SignedAssertionValue hiddenState = resolveSignedAssertionValue(source, starts, lengths, prior, 1, 48);
        assert(!hiddenState.valid);
        set(prior, 0, -19);
        set(prior, 1, -19);
        SignedAssertionValue duplicateState = resolveSignedAssertionValue(source, starts, lengths, prior, 2, 48);
        assert(!duplicateState.valid);
        assert(prior[0] == -19);
        assert(prior[1] == -19);
        assert(prior[2] == 0);
        assert(prior[3] == 0);
        set(starts, COMPILER_GLOBAL_NAME_TOKEN, oldStarts[COMPILER_GLOBAL_NAME_TOKEN]);
        set(lengths, COMPILER_GLOBAL_NAME_TOKEN, oldLengths[COMPILER_GLOBAL_NAME_TOKEN]);
        drop(prior);
        drop(scratch);
        """);
    NativeSourceFrontFixture.check(program, """
        // café 𝄞
        classical class Subject {
          const long item = -7;
          const boolean flag = true;
          state long observed = 0;
          entry void main() {
            long item = 1;
            boolean item = false;
            long other = 0;
            assert(item < observed);
          }
        }
        """, machine -> {});
  }

  @Test
  void admitsParameterCoordinatesOnlyThroughTheRetainedSignedTypeColumn() throws Exception {
    var program = NativeSourceFrontFixture.program(OWNERS, 1, "", """
        long[16] types = new long[16](1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 1, 1);
        long slot = 0;
        while (slot < 16) limit 16 {
          boolean admitted = signedAssertionParameterValid(1, slot, types, 16);
          assert(admitted == (types[slot] == 1));
          slot += 1;
        }
        assert(signedAssertionParameterValid(1, 16, types, 16));
        assert(signedAssertionParameterValid(1, 255, types, 16));
        assert(signedAssertionParameterValid(1, 256, types, 16) == false);
        assert(signedAssertionParameterValid(1, -1, types, 16) == false);
        assert(signedAssertionParameterValid(0, -9223372036854775808, types, 16));
        assert(signedAssertionParameterValid(0, 9223372036854775807, types, 0));
        assert(signedAssertionParameterValid(2, 0, types, 16));
        assert(signedAssertionParameterValid(0, 0, types, -1) == false);
        assert(signedAssertionParameterValid(0, 0, types, 17) == false);
        assert(signedAssertionParameterValid(0, 0, types, -9223372036854775808) == false);
        assert(signedAssertionParameterValid(0, 0, types, 9223372036854775807) == false);
        """);
    NativeSourceFrontFixture.check(program, "", machine -> {});
  }

  @Test
  void checksEveryOriginPairBeforeArithmeticAndKeepsFullWidthLiteralValues() throws Exception {
    var program = NativeSourceFrontFixture.program(List.of("wheeler.compiler.signed_ordering_kinds"),
        1, "", """
        long left = 0;
        while (left < 3) limit 3 {
          long right = 0;
          while (right < 3) limit 3 {
            long opcode = signedOrderingKind(left, right);
            assert(opcode == 43008 + left * 3 + right);
            assert(signedOrderingStatement(opcode));
            assert(signedOrderingLeftKind(opcode) == left);
            assert(signedOrderingRightKind(opcode) == right);
            right += 1;
          }
          left += 1;
        }
        long minimum = -9223372036854775808;
        long maximum = 9223372036854775807;
        assert(signedOrderingKind(-1, 0) == -1);
        assert(signedOrderingKind(0, -1) == -1);
        assert(signedOrderingKind(3, 0) == -1);
        assert(signedOrderingKind(0, 3) == -1);
        assert(signedOrderingKind(minimum, 0) == -1);
        assert(signedOrderingKind(0, minimum) == -1);
        assert(signedOrderingKind(maximum, 0) == -1);
        assert(signedOrderingKind(0, maximum) == -1);
        assert(signedOrderingLeftKind(minimum) == -1);
        assert(signedOrderingRightKind(maximum) == -1);
        assert(signedOrderingValueValid(0, minimum));
        assert(signedOrderingValueValid(0, maximum));
        assert(signedOrderingValueValid(1, 255));
        assert(signedOrderingValueValid(1, 256) == false);
        assert(signedOrderingValueValid(2, 0));
        assert(signedOrderingValueValid(2, 1) == false);
        assert(signedOrderingValueValid(-1, 0) == false);
        assert(signedOrderingValueValid(3, 0) == false);
        assert(signedOrderingValueValid(maximum, 0) == false);
        """);
    NativeSourceFrontFixture.check(program, "", machine -> {
      org.junit.jupiter.api.Assertions.assertEquals(7, machine.snapshot().buffers().size());
    });
  }

  @Test
  void rejectsInvalidWindowsAndPriorTablesBeforeValueReadsAndRewinds() throws Exception {
    var program = NativeSourceFrontFixture.program(OWNERS, 4096,
        "private const long SCRATCH_BYTES = 32792;", """
        region scratch = new region(/* bytes= */ SCRATCH_BYTES, /* allocations= */ 2);
        words prior = allocate(scratch, 4);
        words shortColumn = allocate(scratch, 4095);
        long minimum = -9223372036854775808;
        long maximum = 9223372036854775807;
        SignedAssertionValue a = resolveSignedAssertionValue(source, starts, lengths, prior, 0, minimum);
        SignedAssertionValue b = resolveSignedAssertionValue(source, starts, lengths, prior, 0, maximum);
        SignedAssertionValue c = resolveSignedAssertionValue(source, shortColumn, lengths, prior, 0, 0);
        SignedAssertionValue d = resolveSignedAssertionValue(source, starts, shortColumn, prior, 0, 0);
        SignedAssertionValue e = resolveSignedAssertionValue(source, starts, lengths, prior, minimum, 0);
        SignedAssertionValue f = resolveSignedAssertionValue(source, starts, lengths, prior, maximum, 0);
        SignedAssertionValue g = resolveSignedAssertionValue(source, starts, lengths, prior, 5, 0);
        assert(!a.valid);
        assert(!b.valid);
        assert(!c.valid);
        assert(!d.valid);
        assert(!e.valid);
        assert(!f.valid);
        assert(!g.valid);
        set(prior, 0, minimum);
        SignedAssertionValue h = resolveSignedAssertionValue(source, starts, lengths, prior, 1, 0);
        set(prior, 0, maximum);
        SignedAssertionValue i = resolveSignedAssertionValue(source, starts, lengths, prior, 1, 0);
        assert(!h.valid);
        assert(!i.valid);
        set(starts, 0, minimum);
        SignedAssertionValue j = resolveSignedAssertionValue(source, starts, lengths, prior, 0, 0);
        set(starts, 0, maximum);
        SignedAssertionValue k = resolveSignedAssertionValue(source, starts, lengths, prior, 0, 0);
        set(starts, 0, oldStarts[0]);
        set(lengths, 0, maximum);
        SignedAssertionValue l = resolveSignedAssertionValue(source, starts, lengths, prior, 0, 0);
        set(lengths, 0, -1);
        SignedAssertionValue m = resolveSignedAssertionValue(source, starts, lengths, prior, 0, 0);
        set(lengths, 0, oldLengths[0]);
        assert(!j.valid);
        assert(!k.valid);
        assert(!l.valid);
        assert(!m.valid);
        assert(prior[0] == maximum);
        assert(prior[1] == 0);
        assert(prior[2] == 0);
        assert(prior[3] == 0);
        drop(shortColumn);
        drop(prior);
        drop(scratch);
        """);
    NativeSourceFrontFixture.check(program, "// café 𝄞\n-9223372036854775808", machine -> {
      org.junit.jupiter.api.Assertions.assertEquals(9, machine.snapshot().buffers().size());
    });
  }
}
