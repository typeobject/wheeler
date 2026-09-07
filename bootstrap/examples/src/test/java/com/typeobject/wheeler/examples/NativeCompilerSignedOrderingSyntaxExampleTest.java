package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertEquals;

import com.typeobject.wheeler.core.vm.MachineStatus;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import java.nio.charset.StandardCharsets;
import java.util.List;
import org.junit.jupiter.api.Test;

/** Counted assertion syntax does not bind names, evaluate values, or read a following token. */
final class NativeCompilerSignedOrderingSyntaxExampleTest {
  private static final List<String> OWNERS = List.of("wheeler.compiler.signed_ordering_syntax");

  @Test
  void admitsBothOperandExtentsWithoutTypeOrValueAdmissionAndRewinds() throws Exception {
    var program = NativeSourceFrontFixture.program(OWNERS, 4096, "", """
        SignedOrderingFront front = signedOrderingFront(source, kinds, starts, lengths, 0, count);
        assert(front.valid);
        assert(front.leftToken == 2);
        assert(front.nextToken == count);
        assert(front.rightToken == signedOrderingRightToken(source, starts, lengths, 0));
        assert(signedOrderingCandidate(source, starts, lengths, 0));
        """);
    for (String source : List.of("assert(left < right);", "assert(-1 < -0);",
        "assert(-0x8000000000000000 < 0x7fffffffffffffff);", "assert(public < reverse);",
        "assert(missing < true);", "assert(9223372036854775808 < -9223372036854775809);")) {
      NativeSourceFrontFixture.check(program, "// café 𝄞\n" + source, machine -> {
        assertEquals(7, machine.snapshot().buffers().size());
      });
    }
  }

  @Test
  void rejectsMalformedOperandsAndTailsWithoutPublicationAndRewinds() throws Exception {
    var program = NativeSourceFrontFixture.program(OWNERS, 4096,
        "state long left = 91; state long right = 92; state long next = 93; state long published = 0;", """
        SignedOrderingFront front = signedOrderingFront(source, kinds, starts, lengths, 0, count);
        if (front.valid) {
          left = front.leftToken;
          right = front.rightToken;
          next = front.nextToken;
          published = 1;
        }
        """);
    for (String source : List.of("", "assert", "assert(", "expect(a < b);", "assert a < b;",
        "assert(< b);", "assert(a <);", "assert(-name < b);", "assert(a < -name);",
        "assert(a < b)", "assert(a < b];", "assert(a <= b);", "assert(a < b + 1);",
        "assert(a + 1 < b);", "assert((a) < b);", "assert(a < (b));", "assert(a < b < c);")) {
      NativeSourceFrontFixture.check(program, source, machine -> {
        assertEquals(91, machine.global("left"), source);
        assertEquals(92, machine.global("right"), source);
        assertEquals(93, machine.global("next"), source);
        assertEquals(0, machine.global("published"), source);
        assertEquals(7, machine.snapshot().buffers().size());
      });
    }
  }

  @Test
  void checksCountedWindowsWithShortBackingBeforeAnyReadAndRewinds() throws Exception {
    var program = NativeSourceFrontFixture.program(OWNERS, 8, "", """
        assert(count == 7);
        SignedOrderingFront accepted = signedOrderingFront(source, kinds, starts, lengths, 0, count);
        assert(accepted.valid);
        assert(accepted.leftToken == 2);
        assert(accepted.rightToken == 4);
        assert(accepted.nextToken == 7);
        assert(signedOrderingCandidate(source, starts, lengths, 0) == false);
        long minimum = -9223372036854775808;
        long maximum = 9223372036854775807;
        SignedOrderingFront a = signedOrderingFront(source, kinds, starts, lengths, minimum, count);
        SignedOrderingFront b = signedOrderingFront(source, kinds, starts, lengths, maximum, count);
        SignedOrderingFront c = signedOrderingFront(source, kinds, starts, lengths, 0, minimum);
        SignedOrderingFront d = signedOrderingFront(source, kinds, starts, lengths, 0, maximum);
        SignedOrderingFront e = signedOrderingFront(source, kinds, starts, lengths, 0, 9);
        SignedOrderingFront f = signedOrderingFront(source, kinds, starts, lengths, count, count);
        SignedOrderingFront g = signedOrderingFront(source, kinds, starts, lengths, 0, count - 1);
        assert(!a.valid);
        assert(!b.valid);
        assert(!c.valid);
        assert(!d.valid);
        assert(!e.valid);
        assert(!f.valid);
        assert(!g.valid);
        assert(signedOrderingCandidate(source, starts, lengths, minimum) == false);
        assert(signedOrderingCandidate(source, starts, lengths, maximum) == false);
        """);
    NativeSourceFrontFixture.check(program, "assert(a < b);", machine -> {});
  }

  @Test
  void keepsTheLastTokenAndRejectsExcessWithSufficientBacking() throws Exception {
    var program = NativeSourceFrontFixture.program(OWNERS, 4097,
        "state long admitted = 0; state long left = -1; state long right = -1; state long next = -1;", """
        assert(count == 4096);
        SignedOrderingFront excess = signedOrderingFront(source, kinds, starts, lengths, 4088, count + 1);
        assert(!excess.valid);
        assert(excess.leftToken == -1);
        assert(excess.rightToken == -1);
        assert(excess.nextToken == -1);
        SignedOrderingFront front = signedOrderingFront(source, kinds, starts, lengths, 4088, count);
        if (front.valid) {
          admitted = 1;
          left = front.leftToken;
          right = front.rightToken;
          next = front.nextToken;
        }
        """);
    String source = "x;".repeat(2044) + "assert(-1 < b);";
    var machine = new VirtualMachine(program, source.getBytes(StandardCharsets.UTF_8));
    for (int steps = 0; steps < 4_000_000 && machine.status() != MachineStatus.HALTED; steps++) {
      machine.stepWithoutRewindHistory();
    }
    assertEquals(MachineStatus.HALTED, machine.status());
    assertEquals(1, machine.global("admitted"));
    assertEquals(4090, machine.global("left"));
    assertEquals(4093, machine.global("right"));
    assertEquals(4096, machine.global("next"));
    assertEquals(7, machine.snapshot().buffers().size());
  }
}
