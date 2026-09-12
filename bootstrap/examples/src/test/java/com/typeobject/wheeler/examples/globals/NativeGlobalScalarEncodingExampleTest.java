package com.typeobject.wheeler.examples.globals;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.BytecodeFormat;
import com.typeobject.wheeler.core.bytecode.Instruction;
import com.typeobject.wheeler.core.bytecode.Opcode;
import com.typeobject.wheeler.core.vm.MachineStatus;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import com.typeobject.wheeler.examples.CompilerSources;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import org.junit.jupiter.api.Test;

/** Exact scalar location encodings, terminal frames, and rejection before any code publication. */
final class NativeGlobalScalarEncodingExampleTest {
  private static final int CODE_BYTES = 262144;
  private static final int FRAME_LOCALS = 256;
  private static final int GLOBALS = 8;
  private static final int SOURCE = 1;
  private static final int BINARY_SOURCES = 3;
  private static final int LITERAL = 5;
  private static final int SENTINEL = 211;
  private static final int MOVE = Opcode.LOCAL_MOVE.code();
  private static final int LOAD = Opcode.LOCAL_LOAD_GLOBAL.code();
  private static final int STORE = Opcode.LOCAL_STORE_GLOBAL.code();
  private static final int RETURN = Opcode.RETURN_VALUE.code();
  private static final int SOURCE_BYTES = Instruction.of(Opcode.LOCAL_LOAD_GLOBAL, 0, 0).encodedLength()
      + Instruction.of(Opcode.RETURN_VALUE, 0).encodedLength();
  private static final int STORE_BYTES = Instruction.of(Opcode.LOCAL_LOAD_GLOBAL, 0, 0).encodedLength()
      + Instruction.of(Opcode.LOCAL_STORE_GLOBAL, 0, 0).encodedLength();

  private record Case(int kind, long cursor, long base, int leftOpcode, long left,
                      int rightOpcode, long right, int destinationOpcode, long destination, boolean valid) {}

  @Test
  void emitsTerminalLocalsAndDeclarationOrdinalsWithoutChangingInactiveBytes() throws Exception {
    for (Case row : List.of(
        new Case(SOURCE, 3, FRAME_LOCALS - 1, LOAD, GLOBALS - 1, MOVE, 0, RETURN, 0, true),
        new Case(SOURCE, CODE_BYTES - STORE_BYTES, 0, LOAD, GLOBALS - 1, MOVE, 0, STORE, GLOBALS - 1, true),
        new Case(SOURCE, 3, 0, MOVE, FRAME_LOCALS - 1, MOVE, 0, STORE, GLOBALS - 1, true),
        new Case(BINARY_SOURCES, 3, FRAME_LOCALS - 3, LOAD, GLOBALS - 1, MOVE, FRAME_LOCALS - 1, STORE, 0, true),
        new Case(BINARY_SOURCES, 3, 0, LOAD, 0, LOAD, GLOBALS - 1, RETURN, 0, true),
        new Case(LITERAL, 3, FRAME_LOCALS - 1, MOVE, Long.MIN_VALUE, MOVE, 0, STORE, GLOBALS - 1, true))) {
      check(row);
    }
  }

  @Test
  void rejectsMalformedLocationsAndFirstExcessBeforeWritingAnyInstruction() throws Exception {
    for (Case row : List.of(
        new Case(SOURCE, -1, 0, LOAD, 0, MOVE, 0, RETURN, 0, false),
        new Case(SOURCE, Long.MAX_VALUE, 0, LOAD, 0, MOVE, 0, RETURN, 0, false),
        new Case(SOURCE, CODE_BYTES - SOURCE_BYTES + 1, 0, LOAD, 0, MOVE, 0, RETURN, 0, false),
        new Case(SOURCE, CODE_BYTES - STORE_BYTES + 1, 0, LOAD, 0, MOVE, 0, STORE, 0, false),
        new Case(SOURCE, 3, -1, LOAD, 0, MOVE, 0, RETURN, 0, false),
        new Case(SOURCE, 3, FRAME_LOCALS, LOAD, 0, MOVE, 0, RETURN, 0, false),
        new Case(SOURCE, 3, 0, LOAD, -1, MOVE, 0, RETURN, 0, false),
        new Case(SOURCE, 3, 0, LOAD, GLOBALS, MOVE, 0, RETURN, 0, false),
        new Case(SOURCE, 3, 0, MOVE, FRAME_LOCALS, MOVE, 0, RETURN, 0, false),
        new Case(SOURCE, 3, 0, Opcode.LOCAL_CONST.code(), 0, MOVE, 0, RETURN, 0, false),
        new Case(SOURCE, 3, 0, LOAD, 0, Opcode.LOCAL_CONST.code(), 0, RETURN, 0, false),
        new Case(SOURCE, 3, 0, LOAD, 0, LOAD, 0, RETURN, 0, false),
        new Case(SOURCE, 3, 0, LOAD, 0, MOVE, 0, STORE, -1, false),
        new Case(SOURCE, 3, 0, LOAD, 0, MOVE, 0, STORE, GLOBALS, false),
        new Case(SOURCE, 3, 0, LOAD, 0, MOVE, 0, Opcode.LOCAL_CONST.code(), 0, false),
        new Case(BINARY_SOURCES, 3, FRAME_LOCALS - 2, LOAD, 0, MOVE, 0, RETURN, 0, false),
        new Case(BINARY_SOURCES, 3, 0, MOVE, 0, LOAD, GLOBALS, RETURN, 0, false),
        new Case(LITERAL, 3, 0, LOAD, 0, MOVE, 0, STORE, 0, false))) {
      check(row);
    }
  }

  private static void check(Case row) throws Exception {
    byte[] expected = new byte[CODE_BYTES];
    expected[0] = (byte) SENTINEL;
    expected[CODE_BYTES - 1] = (byte) SENTINEL;
    List<Instruction> instructions = row.valid() ? reference(row) : List.of();
    int length = instructions.stream().mapToInt(Instruction::encodedLength).sum();
    if (row.valid()) {
      var bytes = ByteBuffer.wrap(expected).order(ByteOrder.LITTLE_ENDIAN).position((int) row.cursor());
      for (var instruction : instructions) {
        bytes.putShort((short) instruction.opcode().code()).putShort((short) instruction.operands().size())
            .putInt(instruction.encodedLength());
        for (long operand : instruction.operands()) bytes.putLong(operand);
      }
      assertEquals(row.cursor() + length, bytes.position());
    }
    assertEquals(Short.BYTES * 2 + Integer.BYTES, BytecodeFormat.INSTRUCTION_HEADER_SIZE);
    var sources = new LinkedHashMap<>(CompilerSources.moduleClosure("wheeler.compiler.closure.direct_scalar_encoding"));
    sources.put("Sha256.w", Files.readString(Path.of("../wheeler-core/src/main/wheeler/crypto/Sha256.w")));
    sources.put("Driver.w", """
        module example.scalar_locations;
        import wheeler.compiler.closure.direct_scalar_encoding;
        classical class Driver {
          const long CODE_BYTES = %d;
          const long MINIMUM = -9223372036854775807 - 1;
          state long prepared = 0;
          state long completed = 0;
          state long valid = 0;
          state long next = 0;
          state long width = 0;
          state long instructions = 0;
          entry void main() {
            region arena = new region(CODE_BYTES, 1);
            bytes code = allocateBytes(arena, CODE_BYTES);
            setByte(code, 0, %d); setByte(code, CODE_BYTES - 1, %d);
            prepared = 1;
            DirectScalarExtent result = writeDirectScalarDestination(code, %s, %d, %s, %d,
              %d, %d, %s, %s, %d, %s, 0);
            if (result.valid) { valid = 1; }
            next = result.next; width = result.localCount; instructions = result.instructionCount;
            completed = 1;
            drop(code); drop(arena);
          }
        }
        """.formatted(CODE_BYTES, SENTINEL, SENTINEL, literal(row.cursor()), row.destinationOpcode(),
            literal(row.destination()), row.kind(), row.leftOpcode(), row.rightOpcode(), literal(row.base()),
            literal(row.left()), row.kind() == BINARY_SOURCES ? Opcode.LOCAL_ADD.code() : 0, literal(row.right())));
    var program = new WheelerCompiler().compileModuleFiles(sources, "example.scalar_locations");
    var machine = new VirtualMachine(program);
    while (machine.global("prepared") == 0) machine.stepWithoutRewindHistory();
    var before = machine.snapshot();
    while (machine.global("completed") == 0) machine.step();
    var after = machine.snapshot();
    assertEquals(row.valid() ? 1 : 0, machine.global("valid"), row.toString());
    assertEquals(row.valid() ? row.cursor() + length : 0, machine.global("next"));
    assertEquals(row.valid() ? (row.kind() == BINARY_SOURCES ? 3 : 1) : 0, machine.global("width"));
    assertEquals(instructions.size(), machine.global("instructions"));
    byte[] actual = new byte[CODE_BYTES];
    var buffer = after.buffers().getFirst();
    for (int index = 0; index < CODE_BYTES; index++) actual[index] = buffer.elements().get(index).byteValue();
    assertArrayEquals(expected, actual, row.toString());
    assertEquals(before.regions(), after.regions());
    assertEquals(before.buffers().size(), after.buffers().size());
    while (machine.historySize() > 0) machine.rewindOne();
    assertEquals(before, machine.snapshot());
    while (machine.global("completed") == 0) machine.step();
    assertEquals(after, machine.snapshot());
    while (machine.status() != MachineStatus.HALTED) machine.step();
    assertTrue(machine.snapshot().buffers().stream().allMatch(value -> value.dropped()));
    assertTrue(machine.snapshot().regions().stream().allMatch(value -> value.dropped()));
    while (machine.historySize() > 0) machine.rewindOne();
    assertEquals(before, machine.snapshot());
  }

  private static List<Instruction> reference(Case row) {
    var result = new ArrayList<Instruction>();
    Opcode first = row.kind() == LITERAL ? Opcode.LOCAL_CONST : row.leftOpcode() == LOAD ? Opcode.LOCAL_LOAD_GLOBAL : Opcode.LOCAL_MOVE;
    result.add(Instruction.of(first, row.base(), row.left()));
    long value = row.base();
    if (row.kind() == BINARY_SOURCES) {
      Opcode second = row.rightOpcode() == LOAD ? Opcode.LOCAL_LOAD_GLOBAL : Opcode.LOCAL_MOVE;
      result.add(Instruction.of(second, row.base() + 1, row.right()));
      value = row.base() + 2;
      result.add(Instruction.of(Opcode.LOCAL_ADD, value, row.base(), row.base() + 1));
    }
    result.add(row.destinationOpcode() == STORE
        ? Instruction.of(Opcode.LOCAL_STORE_GLOBAL, row.destination(), value)
        : Instruction.of(Opcode.RETURN_VALUE, value));
    return result;
  }

  private static String literal(long value) {
    return value == Long.MIN_VALUE ? "MINIMUM" : Long.toString(value);
  }
}
