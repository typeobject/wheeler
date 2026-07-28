package com.typeobject.wheeler.core.vm;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import java.util.TreeSet;
import org.junit.jupiter.api.Test;

/** Tests canonical task selection independently from future spawn opcodes. */
final class TaskSchedulerTest {
  @Test
  void selectsTheNextRunnableIdentityWithCanonicalWraparound() {
    TaskId firstChild = TaskId.ROOT.child(0, 0);
    TaskId secondChild = TaskId.ROOT.child(1, 0);
    TreeSet<TaskId> runnable = new TreeSet<>();
    runnable.add(TaskId.ROOT);
    runnable.add(firstChild);
    runnable.add(secondChild);
    TaskScheduler scheduler = new TaskScheduler();

    assertEquals(firstChild, scheduler.next(runnable));
    scheduler.commit(firstChild);
    assertEquals(secondChild, scheduler.next(runnable));
    scheduler.commit(secondChild);
    assertEquals(TaskId.ROOT, scheduler.next(runnable));
    scheduler.commit(TaskId.ROOT);
    assertEquals(TaskId.ROOT, scheduler.cursor());
  }

  @Test
  void restoresCursorAndRejectsAnEmptyRunnableSet() {
    TaskScheduler scheduler = new TaskScheduler();
    TaskId child = TaskId.ROOT.child(3, 4);
    scheduler.commit(child);
    scheduler.restore(TaskId.ROOT);

    assertEquals(TaskId.ROOT, scheduler.cursor());
    assertThrows(VmTrap.class, () -> scheduler.next(new TreeSet<>()));
    assertThrows(IllegalArgumentException.class, () -> scheduler.commit(null));
  }
}
