package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertThrows;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.BytecodeReader;
import com.typeobject.wheeler.core.bytecode.BytecodeWriter;
import com.typeobject.wheeler.core.vm.BufferValue;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import com.typeobject.wheeler.core.vm.VmTrap;
import com.typeobject.wheeler.examples.StructuredCallSourceProductDriver.ResultProduct;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.util.Arrays;
import java.util.List;
import java.util.Map;
import org.junit.jupiter.api.Test;

/** Result products must reach direct emission without a second signature parser. */
final class NativeCompilerRetainedResultExampleTest {
  @Test
  void preservesVoidSignedAndBooleanArtifactsAndAllCallerStorage() throws Exception {
    accepts("void", "", 0, 0);
    accepts("long", "return 7;", 1, 0);
    accepts("boolean", "return true;", 2, 0);
  }

  @Test
  void usesTheLastCallableAndParameterRowsWithoutReadingAnUnusedResult() throws Exception {
    accepts("long", "return mod;", 1, 4095);
  }

  @Test
  void rejectsInvalidDirectResultProductsBeforeAllocatingCompilerScratch() throws Exception {
    assertDirectPreflight(new ResultProduct(1, 64, 0, -1));
    assertDirectPreflight(new ResultProduct(1, 64, 0, 3));
  }

  @Test
  void checksBackingTheLastConsumedResultAndCountExcessBeforeAllocation() throws Exception {
    assertDirectPreflight(new ResultProduct(1, 63, 0, 1));
    assertDirectPreflight(new ResultProduct(1, 65, 0, 1));
    assertDirectPreflight(new ResultProduct(64, 64, 63, 3));
    assertDirectPreflight(new ResultProduct(65, 64, 0, 1));
  }

  private static void assertDirectPreflight(ResultProduct result) throws Exception {
    String source = "module example.structured_call; classical class StructuredCall { "
        + "public long recurse(long value) { return value; } }";
    int body = source.indexOf('{', source.indexOf("recurse("));
    int length = SourceRanges.matchingClose(source, body) - body + 1;
    var driver = StructuredCallSourceProductDriver.driverWithResultProduct(body, length, result);
    VirtualMachine machine = new VirtualMachine(
        driver, source.getBytes(StandardCharsets.UTF_8), 32_768);
    int target = driver.functions().stream().filter(function -> function.name().equals(
        "wheeler.compiler.closure.structured_source_module_compiler"
            + "::compileStructuredSourceModuleWithTargets"))
        .findFirst().orElseThrow().id();
    while (machine.snapshot().selectedFrames().getLast().functionId() != target) {
      machine.stepWithoutRewindHistory();
    }
    var before = machine.snapshot();
    assertThrows(VmTrap.class, () -> CompilerMachineRunner.runWithoutRewindHistory(machine));
    var after = machine.snapshot();
    assertEquals(before.regions().size(), after.regions().size(), "no compiler arena");
    assertEquals(before.buffers().size(), after.buffers().size(), "no compiler storage");
    assertEquals(before.buffers(), after.buffers());
    assertEquals(before.regions(), after.regions());
    assertEquals(0, machine.global("artifactLength"));
    assertArrayEquals(new byte[32_768], machine.hostOutput());
  }

  @Test
  void rewindsCompilationAndCleanupAfterDiscardingOnlyPreparationHistory() throws Exception {
    var run = NativeRetainedResultFixture.prepare("long", "return 7;", 1, 4095);
    VirtualMachine machine = run.machine();
    var before = machine.snapshot();
    byte[] expected = expected(run.source());
    machine.run();
    assertEquals(1, machine.global("published"));
    assertArrayEquals(expected, Arrays.copyOf(machine.hostOutput(), expected.length));
    while (machine.historySize() > 0) {
      machine.rewindOne();
    }
    assertEquals(before, machine.snapshot());
  }

  @Test
  void rejectsAValueBodyWhoseClosedResultWasChangedToVoid() throws Exception {
    rejects(0);
  }

  @Test
  void rejectsAValueBodyWhoseClosedResultWasChangedToBoolean() throws Exception {
    rejects(2);
  }

  @Test
  void rejectsResultKindsOutsideTheStructuredProfileWithoutPublication() throws Exception {
    for (long result : new long[] {Long.MIN_VALUE, -1, 3, Long.MAX_VALUE}) {
      rejects(result);
    }
  }

  private static byte[] expected(String source) {
    return new BytecodeWriter().write(new WheelerCompiler().compileLibraryModuleFiles(
        Map.of("Results.w", source), "example.results"));
  }

  private static void accepts(String result, String body, int type, int first) throws Exception {
    var run = NativeRetainedResultFixture.prepare(result, body, type, first);
    VirtualMachine machine = run.machine();
    byte[] expected = expected(run.source());
    while (machine.global("published") == 0) {
      machine.stepWithoutRewindHistory();
    }
    assertEquals(expected.length, machine.global("artifactLength"));
    byte[] digest = MessageDigest.getInstance("SHA-256").digest(expected);
    byte[] transport = Arrays.copyOf(expected, expected.length + 32);
    System.arraycopy(digest, 0, transport, expected.length, 32);
    assertArrayEquals(transport, machine.hostOutput());
    List<BufferValue> caller = run.callerBuffers();
    List<BufferValue> actual = machine.snapshot().buffers();
    for (int index = 0; index < caller.size(); index++) {
      BufferValue before = caller.get(index);
      BufferValue after = actual.stream().filter(row -> row.id() == before.id())
          .findFirst().orElseThrow();
      assertFalse(after.dropped());
      if (index == 1) {
        assertBytes(after, transport, 0);
      } else if (index == caller.size() - 2) {
        assertBytes(after, expected, 211);
      } else if (index == caller.size() - 1) {
        assertBytes(after, digest, 211);
      } else {
        assertEquals(before.elements(), after.elements(), "caller buffer " + before.id());
      }
    }
    var artifact = new BytecodeReader().read(Arrays.copyOf(machine.hostOutput(), expected.length));
    VirtualMachine entry = new VirtualMachine(artifact);
    var initial = entry.snapshot();
    entry.run();
    assertEquals(1, entry.historySize());
    entry.rewindOne();
    assertEquals(initial, entry.snapshot());
    CompilerMachineRunner.runWithoutRewindHistory(machine);
    assertEquals(0, machine.historySize());
  }

  private static void rejects(long type) throws Exception {
    var run = NativeRetainedResultFixture.prepare("long", "return 7;", type, 4095);
    new BytecodeReader().read(expected(run.source()));
    VirtualMachine machine = run.machine();
    assertThrows(VmTrap.class, () -> CompilerMachineRunner.runWithoutRewindHistory(machine));
    assertEquals(0, machine.global("published"));
    assertEquals(0, machine.global("artifactLength"));
    assertEquals(0, machine.historySize());
    List<BufferValue> actual = machine.snapshot().buffers();
    for (BufferValue before : run.callerBuffers()) {
      BufferValue after = actual.stream().filter(row -> row.id() == before.id())
          .findFirst().orElseThrow();
      assertFalse(after.dropped());
      assertEquals(before.elements(), after.elements(), "caller buffer " + before.id());
    }
    assertArrayEquals(new byte[32_800], machine.hostOutput());
  }

  private static void assertBytes(BufferValue buffer, byte[] prefix, int tail) {
    for (int cell = 0; cell < buffer.length(); cell++) {
      long expected = cell < prefix.length ? Byte.toUnsignedInt(prefix[cell]) : tail;
      long actual = buffer.elements().get(cell);
      if (expected != actual) {
        assertEquals(expected, actual, "buffer " + buffer.id() + " cell " + cell);
      }
    }
  }
}
