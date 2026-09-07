package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.Instruction;
import com.typeobject.wheeler.core.bytecode.Opcode;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.util.Arrays;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import org.junit.jupiter.api.Test;

/** Two full-width words retain operand order, exact load opcodes, and independent frame bounds. */
final class NativeCompilerSignedOrderingEncodingExampleTest {
  @Test
  void matchesEveryOriginPairAtANonzeroCursorAndRewinds() throws Exception {
    Program encoder = encoder();
    var lefts = List.of("-9223372036854775808", "left", "observed");
    var rights = List.of("9223372036854775807", "right", "observed");
    for (int left = 0; left < 3; left++) {
      for (int right = 0; right < 3; right++) {
        String source = "module example.ordering; classical class Ordering { state long observed = 0; "
            + "entry void main() { long left = -1; long right = 1; assert("
            + lefts.get(left) + " < " + rights.get(right) + "); } }";
        var artifact = new WheelerCompiler().compileModuleFiles(Map.of("Test.w", source), "example.ordering");
        var entry = artifact.function(artifact.entryFunctionId());
        byte[] code = NativeInstructionBytes.encode(entry.forward().subList(4, 8));
        assertEquals(96, code.length);
        assertEquals(List.of(1, 1, 2), entry.localTypes().subList(4, 7).stream()
            .map(type -> type.code()).toList());
        byte[] expected = sentinels(104);
        System.arraycopy(code, 0, expected, 4, code.length);
        long first = left == 0 ? Long.MIN_VALUE : left == 1 ? 1 : 0;
        long second = right == 0 ? Long.MAX_VALUE : right == 1 ? 3 : 0;
        check(encoder, 43008 + left * 3 + right, first, second, 4, 4, expected, 100);
      }
    }
  }

  @Test
  void rejectsBadOriginsSlotsAndWindowsBeforeWritesAndRewinds() throws Exception {
    Program encoder = encoder();
    for (long opcode : List.of(Long.MIN_VALUE, -1L, 8192L, 24832L, 43007L, 43017L, Long.MAX_VALUE)) {
      check(encoder, opcode, 0, 0, 4, 4, sentinels(104), -1);
    }
    for (long value : List.of(Long.MIN_VALUE, -1L, 4L, 255L, 256L, Long.MAX_VALUE)) {
      check(encoder, 43011, value, 1, 4, 4, sentinels(104), -1);
      check(encoder, 43009, 0, value, 4, 4, sentinels(104), -1);
    }
    for (long value : List.of(Long.MIN_VALUE, -1L, 1L, Long.MAX_VALUE)) {
      check(encoder, 43014, value, 1, 4, 4, sentinels(104), -1);
      check(encoder, 43010, 0, value, 4, 4, sentinels(104), -1);
    }
    for (long base : List.of(Long.MIN_VALUE, -1L, 254L, 256L, Long.MAX_VALUE)) {
      check(encoder, 43008, Long.MIN_VALUE, Long.MAX_VALUE, base, 4, sentinels(104), -1);
    }
    for (long cursor : List.of(Long.MIN_VALUE, -1L, 9L, 104L, Long.MAX_VALUE)) {
      check(encoder, 43008, Long.MIN_VALUE, Long.MAX_VALUE, 0, cursor, sentinels(104), -1);
    }
    check(encoder, 43008, Long.MIN_VALUE, Long.MAX_VALUE, 0, 0, sentinels(95), -1);
  }

  @Test
  void fillsTheLastThreeFrameSlotsAndTheExactCodeWindow() throws Exception {
    Program encoder = encoder();
    byte[] code = NativeInstructionBytes.encode(List.of(
        Instruction.of(Opcode.LOCAL_MOVE, 253, 252),
        Instruction.of(Opcode.LOCAL_MOVE, 254, 251),
        Instruction.of(Opcode.LOCAL_LT, 255, 253, 254),
        Instruction.of(Opcode.EXPECT_TRUE, 255)));
    check(encoder, 43012, 252, 251, 253, 0, code, 96);
  }

  private static byte[] sentinels(int count) {
    byte[] result = new byte[count];
    Arrays.fill(result, (byte) 73);
    return result;
  }

  private static void check(Program program, long opcode, long left, long right, long base,
      long cursor, byte[] expected, long end) {
    byte[] input = ByteBuffer.allocate(40).order(ByteOrder.LITTLE_ENDIAN)
        .putLong(opcode).putLong(left).putLong(right).putLong(base).putLong(cursor).array();
    var machine = VirtualMachine.withBinaryInput(program, input, expected.length);
    var initial = machine.snapshot();
    machine.run();
    assertArrayEquals(expected, machine.hostOutput(), "opcode " + opcode);
    assertEquals(end < 0 ? 91 : end, machine.global("written"));
    assertEquals(end < 0 ? 0 : 1, machine.global("published"));
    assertEquals(2, machine.snapshot().buffers().size());
    while (machine.historySize() > 0) { machine.rewindOne(); }
    assertEquals(initial, machine.snapshot());
  }

  private static Program encoder() throws Exception {
    var modules = new LinkedHashMap<String, String>();
    modules.putAll(CompilerSources.moduleClosure("wheeler.compiler.signed_ordering_encoding"));
    modules.putAll(CompilerSources.moduleClosure("wheeler.compiler.local_opcodes"));
    CoreSources.addBinaryClosure(modules);
    modules.put("OrderingEncoder.w", """
        module example.ordering_encoder;
        import wheeler.compiler.local_opcodes;
        import wheeler.compiler.signed_ordering_encoding;
        import wheeler.compiler.signed_ordering_kinds;
        import wheeler.core.encoding.binary;
        classical class OrderingEncoder {
          state long written = 91;
          state long published = 0;
          entry void main(borrow byteview input, borrow mut bytes output) {
            long opcode = readSigned(input, 0);
            long left = readSigned(input, 8);
            long right = readSigned(input, 16);
            long localBase = readSigned(input, 24);
            long cursor = readSigned(input, 32);
            long byte = 0;
            while (byte < bufferLength(output)) limit 128 {
              setByte(output, byte, 73);
              byte += 1;
            }
            long end = writeSignedOrderingAssertion(output, cursor, opcode, left, right, localBase);
            if (-1 < end) {
              written = end;
              published = 1;
            }
            if (signedOrderingStatement(opcode)) {
              assert(statementLocalCount(opcode) == 3);
              assert(statementInstructionCount(opcode) == 4);
              assert(statementCodeLength(opcode) == 96);
            }
          }
        }
        """);
    return new WheelerCompiler().compileModuleFiles(modules, "example.ordering_encoder");
  }
}
