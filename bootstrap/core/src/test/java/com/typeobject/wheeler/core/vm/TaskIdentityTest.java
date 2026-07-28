package com.typeobject.wheeler.core.vm;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import com.typeobject.wheeler.core.ProgramFixtures;
import java.util.ArrayList;
import java.util.List;
import org.junit.jupiter.api.Test;

/** Tests stable task and event origin identities before structured spawning lands. */
final class TaskIdentityTest {
  @Test
  void ordersHierarchicalTaskIdentitiesCanonically() {
    TaskId left = TaskId.ROOT.child(0, 1);
    TaskId nested = left.child(2, 3);
    TaskId right = TaskId.ROOT.child(1, 0);

    assertEquals("root", TaskId.ROOT.canonicalName());
    assertEquals("root/0.1/2.3", nested.canonicalName());
    assertEquals(List.of(TaskId.ROOT, left, nested, right),
        new ArrayList<>(List.of(right, nested, left, TaskId.ROOT)).stream().sorted().toList());
    assertThrows(IllegalArgumentException.class, () -> TaskId.ROOT.child(-1, 0));
  }

  @Test
  void snapshotsAndObservationsUseRootTaskZero() {
    List<TransitionObserver.Observation> observations = new ArrayList<>();
    VirtualMachine machine = new VirtualMachine(ProgramFixtures.counter(), observations::add);

    assertEquals(TaskId.ROOT, machine.snapshot().selectedTask());
    assertEquals(0, machine.snapshot().workflowEpoch());
    machine.step();
    machine.rewindOne();

    EventId executed = new EventId(0, TaskId.ROOT, 1);
    assertEquals(executed, observations.get(0).eventId());
    assertEquals(executed, observations.get(1).eventId());
    assertEquals(TransitionObserver.Direction.FORWARD, observations.get(0).direction());
    assertEquals(TransitionObserver.Direction.REWIND_FORWARD, observations.get(1).direction());
  }

  @Test
  void enforcesTaskAndEventIdentityBounds() {
    TaskId deepest = TaskId.ROOT;
    for (int depth = 0; depth < TaskId.MAX_DEPTH; depth++) {
      deepest = deepest.child(depth, 0);
    }
    TaskId atLimit = deepest;

    assertThrows(IllegalArgumentException.class, () -> atLimit.child(0, 0));
    assertThrows(IllegalArgumentException.class, () -> EventId.root(-1));
  }
}
