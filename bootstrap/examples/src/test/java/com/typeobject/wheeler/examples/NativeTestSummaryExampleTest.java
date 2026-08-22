package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import com.typeobject.wheeler.core.vm.VmTrap;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.security.MessageDigest;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import org.junit.jupiter.api.Test;

/** Native evidence for arrival-independent test summary reduction. */
final class NativeTestSummaryExampleTest {
  private static Program compiledProgram;

  @Test
  void reducesArrivalIndependentOutcomes() throws Exception {
    Outcome alpha = new Outcome(identity("alpha"), 0);
    Outcome beta = new Outcome(identity("beta"), 1);
    Outcome gamma = new Outcome(identity("gamma"), 0);
    byte[] expected = new byte[] {3, 0, 2, 0, 1, 0, 0};

    assertArrayEquals(expected, execute(frame(List.of(alpha, beta, gamma))));
    assertArrayEquals(expected, execute(frame(List.of(gamma, alpha, beta))));
  }

  @Test
  void acceptsEmptyAndAllPassingSummaries() throws Exception {
    assertArrayEquals(
        new byte[] {0, 0, 0, 0, 0, 0, 1}, execute(frame(List.of())));
    assertArrayEquals(
        new byte[] {2, 0, 2, 0, 0, 0, 1},
        execute(frame(List.of(
            new Outcome(identity("left"), 0),
            new Outcome(identity("right"), 0)))));
  }

  @Test
  void rejectsDuplicateIdentitiesAndUnknownStatusesBeforePublication() throws Exception {
    byte[] duplicate = identity("duplicate");
    assertRejected(frame(List.of(
        new Outcome(duplicate, 0),
        new Outcome(identity("middle"), 1),
        new Outcome(duplicate, 1))));
    assertRejected(frame(List.of(new Outcome(identity("unknown"), 2))));
  }

  private static byte[] identity(String value) throws Exception {
    return MessageDigest.getInstance("SHA-256")
        .digest(value.getBytes(StandardCharsets.UTF_8));
  }

  private static byte[] frame(List<Outcome> outcomes) {
    ByteBuffer input = ByteBuffer.allocate(2 + outcomes.size() * 33)
        .order(ByteOrder.LITTLE_ENDIAN)
        .putShort((short) outcomes.size());
    for (Outcome outcome : outcomes) {
      input.put(outcome.identity()).put((byte) outcome.status());
    }
    return input.array();
  }

  private static void assertRejected(byte[] input) throws Exception {
    VirtualMachine machine = VirtualMachine.withBinaryInput(program(), input, 7);
    assertThrows(VmTrap.class, () -> CompilerMachineRunner.runWithoutRewindHistory(machine));
    assertArrayEquals(new byte[7], machine.hostOutput());
  }

  private static byte[] execute(byte[] input) throws Exception {
    VirtualMachine machine = VirtualMachine.withBinaryInput(program(), input, 7);
    CompilerMachineRunner.runWithoutRewindHistory(machine);
    return machine.hostOutput();
  }

  private static synchronized Program program() throws Exception {
    if (compiledProgram != null) {
      return compiledProgram;
    }

    Map<String, String> sources = new LinkedHashMap<>();
    CoreSources.addBinaryClosure(sources);
    sources.put(
        "TestSummary.w",
        Files.readString(Path.of(
            "../wheeler-runtime/src/main/wheeler/runtime/testing/TestSummary.w")));
    sources.put(
        "NativeTestSummary.w",
        Files.readString(Path.of(
            "../wheeler-conformance/src/main/wheeler/testing/NativeTestSummary.w")));
    compiledProgram = new WheelerCompiler().compileModuleFiles(
        sources, "wheeler.conformance.testing.native_test_summary");
    return compiledProgram;
  }

  private record Outcome(byte[] identity, int status) {}
}
