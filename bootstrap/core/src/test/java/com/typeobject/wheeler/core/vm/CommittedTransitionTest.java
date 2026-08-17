package com.typeobject.wheeler.core.vm;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import com.typeobject.wheeler.core.ProgramFixtures;
import java.util.ArrayList;
import java.util.List;
import org.junit.jupiter.api.Test;

/** Conformance tests for root-task execution without retained rewind history. */
final class CommittedTransitionTest {
  @Test
  void retainsNoRewindState() {
    VirtualMachine machine = new VirtualMachine(ProgramFixtures.counter());

    while (machine.status() != MachineStatus.HALTED) {
      machine.stepWithoutRewindHistory();
    }

    assertEquals(0, machine.global("count"));
    assertEquals(0, machine.historySize());
    assertThrows(VmTrap.class, machine::rewindOne);
  }

  @Test
  void preservesObservedRootTaskTransitions() {
    List<TransitionObserver.Observation> rewindableObservations = new ArrayList<>();
    List<TransitionObserver.Observation> committedObservations = new ArrayList<>();
    VirtualMachine rewindable = new VirtualMachine(
        ProgramFixtures.counter(), rewindableObservations::add);
    VirtualMachine committed = new VirtualMachine(
        ProgramFixtures.counter(), committedObservations::add);

    while (rewindable.status() != MachineStatus.HALTED) {
      rewindable.step();
      committed.stepWithoutRewindHistory();
    }

    assertEquals(rewindableObservations, committedObservations);
    assertEquals(rewindable.snapshot().selectedTask(), committed.snapshot().selectedTask());
    assertEquals(rewindable.snapshot().schedulerCursor(), committed.snapshot().schedulerCursor());
    assertEquals(rewindable.snapshot().status(), committed.snapshot().status());
    assertEquals(rewindable.snapshot().taskStatuses(), committed.snapshot().taskStatuses());
    assertEquals(rewindable.snapshot().taskFrames(), committed.snapshot().taskFrames());
    assertEquals(rewindable.snapshot().globals(), committed.snapshot().globals());
    assertEquals(rewindable.snapshot().sequence(), committed.snapshot().sequence());
    assertEquals(0, committed.historySize());
  }

  @Test
  void rejectsAnExistingRewindTail() {
    VirtualMachine machine = new VirtualMachine(ProgramFixtures.counter());
    machine.step();

    assertThrows(VmTrap.class, machine::stepWithoutRewindHistory);
    machine.commitHistory();
    machine.stepWithoutRewindHistory();
    assertEquals(0, machine.historySize());
  }
}
