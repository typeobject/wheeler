package com.typeobject.wheeler.examples.globals;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import com.typeobject.wheeler.core.vm.VirtualMachine;
import com.typeobject.wheeler.core.vm.VmTrap;
import java.util.List;
import java.util.stream.Collectors;
import java.util.stream.IntStream;
import java.util.stream.Stream;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.MethodSource;
import org.junit.jupiter.params.provider.ValueSource;

/** Checks source state products without admitting state reads as immutable constants. */
final class NativeSourceGlobalProductsExampleTest {
  @ParameterizedTest
  @MethodSource("acceptedMembers")
  void bindsDeclarationOrderedSignedProductsAndReplays(String members) throws Exception {
    String source = SourceGlobalFixture.source(members);
    var expected = SourceGlobalFixture.oracle(source);
    VirtualMachine machine = SourceGlobalFixture.machine(source);
    var initial = machine.snapshot();
    SourceGlobalFixture.run(machine, true);
    SourceGlobalFixture.assertCaller(machine, source, expected, true, true);
    var completed = machine.snapshot();
    rewind(machine);
    assertEquals(initial, machine.snapshot());
    SourceGlobalFixture.run(machine, true);
    assertEquals(completed, machine.snapshot());
    SourceGlobalFixture.finish(machine, true);
    rewind(machine);
    assertEquals(initial, machine.snapshot());
  }

  static Stream<String> acceptedMembers() {
    return Stream.of(
        "",
        "state long observed = 0;",
        "state long Zulu = -9223372036854775808; state long Alpha = 9223372036854775807;",
        "state long observed = example.values::LIMIT + LOCAL * 2;",
        "public state long observed = LOCAL - LIMIT;",
        "state long value = -7; long value() { return 1; }",
        "// café 𝄞 state long decoy = 9;\nstate long observed = (LOCAL + LIMIT) / 2;",
        "long read() { long state = 7; return state; } state long observed = -1;",
        "record Pair(long value) {} state long observed = 3; enum Flag { case Ready; }");
  }

  @ParameterizedTest
  @ValueSource(strings = {
      "state boolean observed = true;",
      "state long observed;",
      "state long observed = ;",
      "state long observed = true;",
      "state long observed = UNKNOWN;",
      "state long observed = LIMIT / 0;",
      "state long first = 1; state long first = 2;",
      "state long first = 1; state long second = first;",
      "state long first = 1; state long second = example.globals::first;",
      "state long first = 1; nonsense long second = 2;",
      "state long first = 1; long unclosed() {"
  })
  void rejectsTheCompleteBatchWithoutCallerPublication(String members) throws Exception {
    String source = SourceGlobalFixture.source(members);
    VirtualMachine machine = SourceGlobalFixture.machine(source);
    var initial = machine.snapshot();
    SourceGlobalFixture.run(machine, true);
    SourceGlobalFixture.assertCaller(machine, source, List.of(), false, true);
    var rejected = machine.snapshot();
    rewind(machine);
    assertEquals(initial, machine.snapshot());
    SourceGlobalFixture.run(machine, true);
    assertEquals(rejected, machine.snapshot());
    SourceGlobalFixture.finish(machine, true);
    rewind(machine);
    assertEquals(initial, machine.snapshot());
  }

  @ParameterizedTest
  @ValueSource(strings = {
      "9223372036854775807 + 1",
      "-9223372036854775808 - 1",
      "3037000500 * 3037000500"
  })
  void preservesPublicationAndReplaysCheckedArithmeticTraps(String expression) throws Exception {
    String source = SourceGlobalFixture.source(
        "state long first = 1; state long second = " + expression + ";");
    VirtualMachine machine = SourceGlobalFixture.machine(source);
    var initial = machine.snapshot();
    VmTrap trapped = assertThrows(VmTrap.class, () -> SourceGlobalFixture.run(machine, true));
    SourceGlobalFixture.assertCaller(machine, source, List.of(), false, false);
    var rejected = machine.snapshot();
    rewind(machine);
    assertEquals(initial, machine.snapshot());
    VmTrap replayed = assertThrows(VmTrap.class, () -> SourceGlobalFixture.run(machine, true));
    assertEquals(trapped.getMessage(), replayed.getMessage());
    assertEquals(rejected, machine.snapshot());
    rewind(machine);
    assertEquals(initial, machine.snapshot());
  }

  @Test
  void provesAbsenceWithoutConsumingMoreOwnedBuffersOrRegions() throws Exception {
    String source = SourceGlobalFixture.source(
        "record State(long value) {} long read() { long state = 1; return state; }");
    VirtualMachine machine = SourceGlobalFixture.machine(source);
    var initial = machine.snapshot();
    SourceGlobalFixture.prepare(machine);
    var prepared = machine.snapshot();
    SourceGlobalFixture.run(machine, true);
    SourceGlobalFixture.assertCaller(machine, source, List.of(), true, true);
    assertEquals(prepared.regions().size(), machine.snapshot().regions().size());
    assertEquals(prepared.buffers().size(), machine.snapshot().buffers().size());
    SourceGlobalFixture.finish(machine, true);
    rewind(machine);
    assertEquals(initial, machine.snapshot());
  }

  @Test
  void admitsEveryMaximumWidthStateWithoutRetainingHistory() throws Exception {
    String declarations = IntStream.range(0, SourceGlobalFixture.GLOBALS)
        .mapToObj(index -> "state long " + "A".repeat(SourceGlobalFixture.NAME_WIDTH - 1)
            + (char) ('z' - index) + " = " + index + ";")
        .collect(Collectors.joining("\n"));
    String source = SourceGlobalFixture.source(declarations);
    VirtualMachine machine = SourceGlobalFixture.machine(source);
    SourceGlobalFixture.run(machine, false);
    SourceGlobalFixture.assertCaller(machine, source, SourceGlobalFixture.oracle(source), true, true);
    SourceGlobalFixture.finish(machine, false);
    assertEquals(0, machine.historySize());
  }

  @Test
  void rejectsTheFirstExcessStateAndNameWithoutPublishingPredecessors() throws Exception {
    String declarations = IntStream.rangeClosed(0, SourceGlobalFixture.GLOBALS)
        .mapToObj(index -> "state long value" + index + " = " + index + ";")
        .collect(Collectors.joining("\n"));
    for (String members : List.of(declarations,
        "state long first = 1; state long " + "A".repeat(SourceGlobalFixture.NAME_WIDTH + 1)
            + " = 2;")) {
      String source = SourceGlobalFixture.source(members);
      assertTrue(SourceGlobalFixture.oracle(source).size() > 0);
      VirtualMachine machine = SourceGlobalFixture.machine(source);
      SourceGlobalFixture.run(machine, false);
      SourceGlobalFixture.assertCaller(machine, source, List.of(), false, true);
      SourceGlobalFixture.finish(machine, false);
      assertEquals(0, machine.historySize());
    }
  }

  private static void rewind(VirtualMachine machine) {
    while (machine.historySize() > 0) machine.rewindOne();
  }
}
