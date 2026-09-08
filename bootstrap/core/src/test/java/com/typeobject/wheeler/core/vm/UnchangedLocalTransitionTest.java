package com.typeobject.wheeler.core.vm;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import com.typeobject.wheeler.core.bytecode.FunctionBody;
import com.typeobject.wheeler.core.bytecode.Instruction;
import com.typeobject.wheeler.core.bytecode.Opcode;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.bytecode.ValueType;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import org.junit.jupiter.api.Test;

/** Register-version reuse must not elide instructions, observations, or rewind records. */
final class UnchangedLocalTransitionTest {
  @Test
  void recordsEveryInstructionAndRewindsEachCompleteSnapshot() {
    List<TransitionObserver.Observation> observations = new ArrayList<>();
    VirtualMachine machine = new VirtualMachine(program(5, 5), observations::add);
    List<MachineSnapshot> states = new ArrayList<>();
    states.add(machine.snapshot());
    for (int step = 0; step < 5; step++) {
      machine.step();
      assertEquals(step + 1, machine.historySize());
      assertEquals(step, observations.get(step).instructionIndex());
      assertEquals(TransitionObserver.Direction.FORWARD, observations.get(step).direction());
      states.add(machine.snapshot());
    }
    assertEquals(MachineStatus.HALTED, machine.status());
    for (int step = 4; step >= 0; step--) {
      machine.rewindOne();
      assertEquals(states.get(step), machine.snapshot());
      var observed = observations.getLast();
      assertEquals(step, observed.instructionIndex());
      assertEquals(TransitionObserver.Direction.REWIND_FORWARD, observed.direction());
    }
    assertEquals(10, observations.size());
  }

  @Test
  void preservesHistoryFreeObservationsAndIndependentStepLimits() {
    List<TransitionObserver.Observation> retained = new ArrayList<>();
    List<TransitionObserver.Observation> discarded = new ArrayList<>();
    VirtualMachine rewindable = new VirtualMachine(program(5, 5), retained::add);
    VirtualMachine historyFree = new VirtualMachine(program(5, 5), discarded::add);
    for (int step = 0; step < 5; step++) {
      rewindable.step();
      historyFree.stepWithoutRewindHistory();
    }
    assertEquals(retained, discarded);
    assertEquals(rewindable.snapshot().taskFrames(), historyFree.snapshot().taskFrames());
    assertEquals(rewindable.snapshot().sequence(), historyFree.snapshot().sequence());
    assertEquals(MachineStatus.HALTED, historyFree.status());
    assertEquals(0, historyFree.historySize());
    assertThrows(VmTrap.class, historyFree::rewindOne);

    VirtualMachine limited = new VirtualMachine(program(5, 4));
    MachineSnapshot initial = limited.snapshot();
    var failure = assertThrows(VmTrap.class, limited::run);
    assertEquals("Step limit exceeded", failure.getMessage());
    assertEquals(MachineStatus.TRAPPED, limited.status());
    assertEquals(4, limited.snapshot().selectedFrames().getLast().programCounter());
    assertEquals(4, limited.historySize());
    while (limited.historySize() > 0) { limited.rewindOne(); }
    assertEquals(initial, limited.snapshot());
  }

  @Test
  void consumesHistoryCapacityEvenForUnchangedValues() {
    VirtualMachine limited = new VirtualMachine(program(2, 5));
    MachineSnapshot initial = limited.snapshot();
    limited.step();
    limited.step();
    MachineSnapshot before = limited.snapshot();
    var failure = assertThrows(VmTrap.class, limited::step);
    assertEquals("History record limit exceeded", failure.getMessage());
    assertEquals(MachineStatus.TRAPPED, limited.status());
    assertEquals(before.taskFrames(), limited.snapshot().taskFrames());
    assertEquals(before.sequence(), limited.snapshot().sequence());
    assertEquals(2, limited.historySize());
    while (limited.historySize() > 0) { limited.rewindOne(); }
    assertEquals(initial, limited.snapshot());
  }

  private static Program program(int history, int steps) {
    List<ValueType> types = Collections.nCopies(256, ValueType.SIGNED);
    FunctionBody entry = new FunctionBody(0, "main", false, 0, types, null,
        List.of(Instruction.of(Opcode.LOCAL_CONST, 255, 0),
            Instruction.of(Opcode.LOCAL_CONST, 255, 7),
            Instruction.of(Opcode.LOCAL_CONST, 255, 7),
            Instruction.of(Opcode.LOCAL_MOVE, 0, 255),
            Instruction.of(Opcode.HALT)), List.of());
    return new Program("UnchangedLocals", 0, List.of(), List.of(entry), history, steps);
  }
}
