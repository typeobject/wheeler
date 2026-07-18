package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertEquals;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.vm.MachineStatus;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.Map;
import org.junit.jupiter.api.Test;

/** Conformance tests for the Wheeler-owned bounded queue example. */
class WorkQueueExampleTest {
  @Test
  void boundedWheelerQueueReturnsExplicitPushAndPopResults() throws Exception {
    String root = Files.readString(Path.of("src/main/wheeler/WorkQueue.w"));
    String queue = Files.readString(
        Path.of("src/main/wheeler/collections/LongQueue.w"));
    var program = new WheelerCompiler().compileModuleFiles(
        Map.of("WorkQueue.w", root, "LongQueue.w", queue),
        "examples.queue.main");
    VirtualMachine machine = new VirtualMachine(program);
    var initial = machine.snapshot();

    machine.run();

    assertEquals(MachineStatus.HALTED, machine.status());
    assertEquals(4, machine.global("first"));
    assertEquals(9, machine.global("second"));
    assertEquals(2, machine.global("finalHead"));
    assertEquals(4, machine.global("finalTail"));
    assertEquals(1, machine.global("emptyObserved"));
    assertEquals(1, machine.global("fullObserved"));
    while (machine.historySize() > 0) {
      machine.rewindOne();
    }
    assertEquals(initial, machine.snapshot());
  }
}
