package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;
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
import java.util.LinkedHashMap;
import java.util.Map;
import org.junit.jupiter.api.Test;

/** Native evidence for stage-0-compatible test shard assignment. */
final class NativeTestShardExampleTest {
  private static final String IDENTITY =
      "08b5978bc9bc6cdc8c314f5a21375d03369e1a5fa1862a36ba5513fcfe837aac";
  private static Program compiledProgram;

  @Test
  void assignsExactlyOneShardUsingTheCompleteIdentity() throws Exception {
    int shardCount = 7;
    int expected = remainder(IDENTITY, shardCount);
    int selected = 0;

    for (int shardIndex = 0; shardIndex < shardCount; shardIndex++) {
      byte[] output = execute(frame(IDENTITY, shardIndex, shardCount));
      assertArrayEquals(new byte[] {(byte) (shardIndex == expected ? 1 : 0)}, output);
      selected += output[0];
    }

    assertEquals(1, selected);
  }

  @Test
  void retainsLeadingZeroesAndTheFinalOctet() throws Exception {
    String low = "00".repeat(31) + "01";
    String high = "00".repeat(31) + "ff";

    assertArrayEquals(new byte[] {1}, execute(frame(low, remainder(low, 257), 257)));
    assertArrayEquals(new byte[] {1}, execute(frame(high, remainder(high, 257), 257)));
  }

  @Test
  void rejectsNoncanonicalIdentityAndShardRangesBeforePublication() throws Exception {
    byte[] uppercase = frame(IDENTITY.toUpperCase(), 0, 1);
    byte[] zeroCount = frame(IDENTITY, 0, 0);
    byte[] highIndex = frame(IDENTITY, 3, 3);

    assertRejected(uppercase);
    assertRejected(zeroCount);
    assertRejected(highIndex);
  }

  private static void assertRejected(byte[] input) throws Exception {
    VirtualMachine machine = VirtualMachine.withBinaryInput(program(), input, 1);
    assertThrows(VmTrap.class, () -> CompilerMachineRunner.runWithoutRewindHistory(machine));
    assertArrayEquals(new byte[] {0}, machine.hostOutput());
  }

  private static byte[] execute(byte[] input) throws Exception {
    VirtualMachine machine = VirtualMachine.withBinaryInput(program(), input, 1);
    CompilerMachineRunner.runWithoutRewindHistory(machine);
    return machine.hostOutput();
  }

  private static byte[] frame(String identity, int shardIndex, int shardCount) {
    return ByteBuffer.allocate(68)
        .order(ByteOrder.LITTLE_ENDIAN)
        .put(identity.getBytes(StandardCharsets.US_ASCII))
        .putShort((short) shardIndex)
        .putShort((short) shardCount)
        .array();
  }

  private static int remainder(String identity, int shardCount) {
    int remainder = 0;
    for (int offset = 0; offset < identity.length(); offset += 2) {
      int octet = Integer.parseInt(identity, offset, offset + 2, 16);
      remainder = (remainder * 256 + octet) % shardCount;
    }
    return remainder;
  }

  private static synchronized Program program() throws Exception {
    if (compiledProgram != null) {
      return compiledProgram;
    }

    Map<String, String> sources = new LinkedHashMap<>();
    CoreSources.addBinaryClosure(sources);
    sources.put(
        "NativeTestShard.w",
        Files.readString(Path.of(
            "../wheeler-conformance/src/main/wheeler/testing/NativeTestShard.w")));
    compiledProgram = new WheelerCompiler().compileModuleFiles(
        sources, "wheeler.conformance.testing.native_test_shard");
    return compiledProgram;
  }
}
